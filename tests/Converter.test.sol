// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../contracts/Converter.sol";
import "../contracts/EnergyStorage.sol";
import "../contracts/Controller.sol";
import "../contracts/Staking.sol";
import "../contracts/helpers/IConverter.sol";
import "../contracts/helpers/IStaking.sol";
import "../contracts/interfaces/ILiquidityBootstrapAuction.sol";

import "ds-test/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM Genome Mining - Energy Converter contract
 */
contract ConverterTestContract is DSTest, IConverter, IStaking, Util {
    EnergyStorage energyStorage_;
    EnergyStorage lbaEnergyStorage_;
    Converter converterLogic_;
    Controller controller_;
    Staking stakingLogic_;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    ILiquidityBootstrapAuction lba = ILiquidityBootstrapAuction(0x6D08cF8E2dfDeC0Ca1b676425BcFCF1b0e064afA);
    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address deployer = address(this);
    address multisig = deployer; // for the testing we use deployer as a multisig

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        setupContracts();
        setupWallets();
    }

    function setupContracts() internal {
        controller_ = new Controller(multisig);
        energyStorage_ = new EnergyStorage(address(controller_));
        lbaEnergyStorage_ = new EnergyStorage(address(controller_));
        converterLogic_ = new Converter(address(controller_), address(lba), new Period[](0));
        stakingLogic_ = new Staking(address(controller_));

        vm.startPrank(address(controller_));
        energyStorage_.init(address(converterLogic_));
        lbaEnergyStorage_.init(address(converterLogic_));
        converterLogic_.init(multisig, address(energyStorage_), address(lbaEnergyStorage_), address(stakingLogic_));
        vm.stopPrank();
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings
    }

    /** ----------------------------------
     * ! Logic
     * ----------------------------------- */

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND: wallet address is valid
     * @notice  THEN: should get correct consumed amount from mappings
     */
    function testGetConsumedEnergy() public skip(false) {
        assert(converterLogic_.getConsumedEnergy(someone) == 0);

        uint256 newConsumedAmount = 100;
        vm.startPrank(address(converterLogic_));
        energyStorage_.increaseConsumedAmount(someone, newConsumedAmount);
        assert(converterLogic_.getConsumedEnergy(someone) == newConsumedAmount);
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND:  wallet address is invalid
     * @notice  THEN: should revert the message WRONG_ADDRESS
     */
    function testGetConsumedAmount_wrong_wallet() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_ADDRESS));
        converterLogic_.getConsumedEnergy(address(0));
    }

    /**
     * @notice GIVEN: Period struct data (startTime, endTime, astoMultiplier and lpMultiplier)
     * @notice  WHEN: manager calls `addPeriod` or `updatePeriod` function
     * @notice  THEN: period added or updated in the contract
     * @notice  AND: user can call `getCurrentPeriodId`, `getPeriod` or `getCurrentPeriod` to get the data
     */
    function testPeriod_happy_path() public skip(false) {
        vm.startPrank(multisig);

        assert(converterLogic_.periodIdCounter() == 0);

        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        converterLogic_.addPeriod(period);

        vm.warp(startTime + 1 days);

        uint256 periodId = converterLogic_.getCurrentPeriodId();
        assert(converterLogic_.periodIdCounter() == 1);
        assert(periodId == 1);

        Period memory p = converterLogic_.getCurrentPeriod();
        assert(p.startTime == period.startTime);
        assert(p.endTime == period.endTime);
        assert(p.astoMultiplier == period.astoMultiplier);
        assert(p.lpMultiplier == period.lpMultiplier);
        assert(p.lbaLPMultiplier == period.lbaLPMultiplier);

        uint128 startTimeNew = uint128(block.timestamp + 2 days);
        uint128 endTimeNew = startTimeNew + 60 days;
        uint128 astoMultiplierNew = 1.2 * 10**18;
        uint128 lpMultiplierNew = 1.5 * 10**18;
        uint128 lbaLPMultiplierNew = 2 * 10**18;

        Period memory periodNew = Period(
            startTimeNew,
            endTimeNew,
            astoMultiplierNew,
            lpMultiplierNew,
            lbaLPMultiplierNew
        );
        converterLogic_.updatePeriod(periodId, periodNew);

        uint256 periodIdNew = converterLogic_.getCurrentPeriodId();
        assert(converterLogic_.periodIdCounter() == 1);
        assert(periodIdNew == 0);

        Period memory pNew = converterLogic_.getPeriod(periodId);
        assert(pNew.startTime == startTimeNew);
        assert(pNew.endTime == endTimeNew);
        assert(pNew.astoMultiplier == astoMultiplierNew);
        assert(pNew.lpMultiplier == lpMultiplierNew);
        assert(pNew.lbaLPMultiplier == lbaLPMultiplierNew);
    }

    /**
     * @notice GIVEN: Period struct data (startTime, endTime, astoMultiplier and lpMultiplier)
     * @notice  AND: Staking history list (time and amount)
     * @notice  AND: address and periodId
     * @notice  WHEN: user calls `calculateEnergy` function
     * @notice  THEN: return calculated enery based on staking history and token multipliers
     */
    function testEnergyCalculation_with_stake_history() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory astoHistory = new Stake[](3);
        astoHistory[0] = Stake(startTime, 5);
        astoHistory[1] = Stake(startTime + 1 days, 15);
        astoHistory[2] = Stake(startTime + 2 days, 25);

        Stake[] memory lpHistory = new Stake[](1);
        lpHistory[0] = Stake(startTime + 1 days, 2);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );

        vm.warp(startTime + 3 days);
        uint256 energy = converterLogic_.calculateEnergy(someone, converterLogic_.getCurrentPeriodId());
        uint256 expectedEnergy = (5 * 3 + 10 * 2 + 10) * astoMultiplier + 2 * 2 * lpMultiplier;
        assert(energy == expectedEnergy);
    }

    /**
     * @notice GIVEN: Period struct data (startTime, endTime, astoMultiplier and lpMultiplier)
     * @notice  AND: Staking and Unstaking history list (time and amount)
     * @notice  AND: address and periodId
     * @notice  WHEN: user calls `calculateEnergy` function
     * @notice  THEN: return calculated enery based on staking/unstaking history and token multipliers
     */
    function testEnergyCalculation_with_stake_and_unstake_history() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.36 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory astoHistory = new Stake[](3);
        astoHistory[0] = Stake(startTime, 5);
        astoHistory[1] = Stake(startTime + 1 days, 15);
        astoHistory[2] = Stake(startTime + 2 days, 5);

        Stake[] memory lpHistory = new Stake[](1);
        lpHistory[0] = Stake(startTime + 1 days, 2);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );

        vm.warp(startTime + 3 days);
        uint256 energy = converterLogic_.calculateEnergy(someone, converterLogic_.getCurrentPeriodId());
        uint256 expectedEnergy = (5 * 3 + 10) * astoMultiplier + 2 * 2 * lpMultiplier;
        assert(energy == expectedEnergy);
    }

    /**
     * @notice GIVEN: Periods added to converter
     * @notice  AND: tokens staked
     * @notice  AND: address, period id and consumed amount
     * @notice  WHEN: user calls `useEnergy` function
     * @notice  THEN: increase consumed energy in storyage contract
     * @notice  THEN: getConsumedEnergy() returns the new amount
     */
    function testUseEnergy_happy_path() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period[] memory periods = new Period[](2);
        periods[0] = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[1] = Period(endTime, endTime + 60 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);

        vm.startPrank(multisig);
        converterLogic_.addPeriods(periods);
        vm.stopPrank();

        assert(converterLogic_.getConsumedEnergy(someone) == 0);
        assert(converterLogic_.getConsumedLBAEnergy(someone) == 0);

        vm.startPrank(address(controller_));

        Stake[] memory astoHistory = new Stake[](1);
        astoHistory[0] = Stake(startTime, 100);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );
        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(new Stake[](0))
        );
        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );
        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector), abi.encode(10));

        vm.warp(startTime + 1 days);
        converterLogic_.useEnergy(someone, 1, 100 * 10**18);
        vm.stopPrank();
        assert(converterLogic_.getConsumedEnergy(someone) == 85 * 10**18);
        assert(converterLogic_.getConsumedLBAEnergy(someone) == 15 * 10**18);
    }

    /** ----------------------------------
     * ! Contract modifiers
     * ----------------------------------- */

    /**
     * @notice this modifier will skip the test
     */
    modifier skip(bool isSkipped) {
        if (!isSkipped) {
            _;
        }
    }

    /**
     * @notice this modifier will skip the testFail*** tests ONLY
     */
    modifier skipFailing(bool isSkipped) {
        if (isSkipped) {
            require(0 == 1);
        } else {
            _;
        }
    }
}

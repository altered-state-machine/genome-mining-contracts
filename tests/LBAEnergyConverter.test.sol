// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../contracts/Staking.sol";
import "../contracts/Converter.sol";
import "../contracts/LBAEnergyConverter.sol";
import "../contracts/EnergyStorage.sol";
import "../contracts/Controller.sol";
import "../contracts/StakingStorage.sol";
import "../contracts/helpers/IStaking.sol";
import "../contracts/helpers/IConverter.sol";
import "../contracts/helpers/TimeConstants.sol";
import "../contracts/Converter.sol";
import "../contracts/EnergyStorage.sol";
import "../contracts/mocks/MockedERC20.sol";

import "ds-test/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM ASTO Time contract
 */
contract LBAEnergyConverterTestContract is DSTest, Util {
    Staking staker_;
    StakingStorage astoStorage_;
    StakingStorage lpStorage_;
    Converter converter_;
    LBAEnergyConverter lbaConverter_;
    EnergyStorage energyStorage_;
    Controller controller_;
    MockedERC20 astoToken_;
    MockedERC20 lpToken_;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    uint256 amount = 1_234_567_890_000_000_000; // 1.23456789 ASTO
    uint256 initialBalance = 100e18;
    uint256 userBalance = 10e18;
    uint256 astoToken = 0; // tokenId

    ILBA lba_ = ILBA(0x6D08cF8E2dfDeC0Ca1b676425BcFCF1b0e064afA);
    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address deployer = address(this);
    address multisig = deployer; // for the testing we use deployer as a multisig

    uint256 DAY = SECONDS_PER_DAY;
    uint256 SECOND = 1;
    uint256 startTime = 1656540000;
    uint256 day3 = startTime + 3 * DAY;
    uint256 day2 = startTime + 2 * DAY;
    uint256 day1 = startTime + 1 * DAY;

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        vm.clearMockedCalls();

        setupTokens(); // mock tokens
        setupContracts(); // instantiate GM contracts
        mockCalls();
    }

    function setupTokens() internal {
        astoToken_ = new MockedERC20("ASTO Token", "ASTO", deployer, initialBalance);
        lpToken_ = new MockedERC20("Uniswap LP Token", "LP", deployer, initialBalance);
    }

    function setupContracts() internal {
        controller_ = new Controller(multisig);
        staker_ = new Staking(address(controller_));
        astoStorage_ = new StakingStorage(address(controller_));
        lpStorage_ = new StakingStorage(address(controller_));
        lbaConverter_ = new LBAEnergyConverter(address(controller_), lba_);
        converter_ = new Converter(address(controller_));
        energyStorage_ = new EnergyStorage(address(controller_));

        controller_.init(
            address(astoToken_),
            address(astoStorage_),
            address(lpToken_),
            address(lpStorage_),
            address(staker_),
            address(lbaConverter_),
            address(converter_),
            address(energyStorage_)
        );
    }

    function mockCalls() internal {
        vm.mockCall(address(lba_), abi.encodeWithSelector(lba_.claimableLPAmount.selector, someone), abi.encode(1e12));
    }

    /** ----------------------------------
     * ! Busines logic
     * ----------------------------------- */

    /**
     * @notice GIVEN: LPs are not claimed yet
     * @notice  WHEN: two days passed
     * @notice  THEN: energy amount is returned and not zero
     */
    function test_getRemainingLBAEnergy_happy_path() public skip(false) {
        vm.startPrank(address(someone));
        uint256 energy = lbaConverter_.getRemainingLBAEnergy(someone, day2);
        assertEq(energy, 1e12 * 2, "Should be 1e12 * 2 days");
    }

    /**
     * @notice GIVEN: LPs are not claimed yet
     * @notice  WHEN: less than a day passed
     * @notice  THEN: energy amount is returned and not zero
     */
    function test_getRemainingLBAEnergy_not_enough_time_passed() public skip(false) {
        vm.startPrank(address(someone));
        uint256 energy = lbaConverter_.getRemainingLBAEnergy(someone, day1 - 1 * SECOND);
        assertEq(energy, 1e12 * 0, "Should be 0");
    }

    /**
     * @notice GIVEN: LPs are already claimed
     * @notice  WHEN: user calls this function
     * @notice  THEN: energy amount should be zero
     */
    function test_getRemainingLBAEnergy_already_claimed() public skip(false) {
        vm.startPrank(address(someone));
        vm.mockCall(address(lba_), abi.encodeWithSelector(lba_.claimableLPAmount.selector, someone), abi.encode(0));
        uint256 energy = lbaConverter_.getRemainingLBAEnergy(someone, day2);
        assertEq(energy, 0, "Should be 0");
    }

    /**
     * @notice GIVEN: user has an energy available
     * @notice  WHEN: converter contract calls `useLBAEnergy()`
     * @notice  THEN: should return the energy remaining after using
     */
    function test_useLBAEnergy_happy_path() public skip(false) {
        vm.startPrank(address(converter_));
        uint256 remainingEnergy = lbaConverter_.useLBAEnergy(someone, 5e11, day2);
        assertEq(remainingEnergy, 15e11, "Should be  2e12 - 5e11 = 15e11 Ae");

        remainingEnergy = lbaConverter_.useLBAEnergy(someone, 10e11, day2);
        assertEq(remainingEnergy, 5e11, "Should be  2e12 - 5e11 - 10e11 = 5e11 Ae");
    }

    /**
     * @notice GIVEN: user has an energy available
     * @notice  WHEN: NOT a converter contract calls `useLBAEnergy()`
     * @notice  THEN: should revert with access violation error
     */
    function test_useLBAEnergy_not_a_converter() public skip(false) {
        // vm.mockCall(address(lba_), abi.encodeWithSelector(lba_.claimableLPAmount.selector, someone), abi.encode(0));
        vm.startPrank(address(someone));
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0x1cf336fddcc7dc48127faf7a5b80ee54fce73ef647eecd31c24bb6cce3ac3eef"
        );
        uint256 remainingEnergy = lbaConverter_.useLBAEnergy(someone, 5e11, day2);
    }

    /**
     * @notice GIVEN: user has NOT ENOUGH energy available
     * @notice  WHEN: a converter contract calls `useLBAEnergy()`
     * @notice  THEN: should revert with access violation error
     */
    function test_useLBAEnergy_not_enough_energy() public skip(false) {
        vm.mockCall(address(lba_), abi.encodeWithSelector(lba_.claimableLPAmount.selector, someone), abi.encode(0));
        vm.startPrank(address(converter_));
        vm.expectRevert(abi.encodeWithSelector(Util.CalculationsError.selector, NOT_ENOUGH_ENERGY));
        uint256 remainingEnergy = lbaConverter_.useLBAEnergy(someone, 5e11, day2);
    }

    /** ----------------------------------
     * ! Testing modifiers
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

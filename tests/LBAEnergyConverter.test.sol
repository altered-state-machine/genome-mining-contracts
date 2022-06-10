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
import "../contracts/mocks/MockedLBA.sol";

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
    MockedLBA lba_;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    uint256 amount = 1_234_567_890_000_000_000; // 1.23456789 ASTO
    uint256 initialBalance = 100e18;
    uint256 userBalance = 10e18;
    uint256 astoToken = 0; // tokenId

    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address deployer = address(this);
    address multisig = deployer; // for the testing we use deployer as a multisig

    uint256 DAY = SECONDS_PER_DAY;
    uint256 now = block.timestamp;
    uint256 threeDaysAgo = now - DAY * 3;
    uint256 twoDaysAgo = now - DAY * 2;
    uint256 oneDayAgo = block.timestamp - DAY;

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        setupTokens(); // mock tokens
        setupContracts(); // instantiate GM contracts
        setupLBA(); // setup mocked LBA contract
    }

    function setupTokens() internal {
        astoToken_ = new MockedERC20("ASTO Token", "ASTO", deployer, initialBalance);
        lpToken_ = new MockedERC20("Uniswap LP Token", "LP", deployer, initialBalance);
        lba_ = new MockedLBA("LBA LP test token", "LBAT");
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

    function setupLBA() internal {}

    /** ----------------------------------
     * ! Mocked functions
     * ----------------------------------- */

    /**
     * @notice GIVEN: LPs are not claimed yet
     * @notice  WHEN: user calls this function
     * @notice  THEN: energy amount is returned and not zero
     */
    function test_Mocked_functions_work_as_expected() public skip(false) {
        uint256 lpAmount = lba_.claimableLPAmount(someone);
        assertEq(lpAmount, 1e12, "Mocked function should return 1e12");

        lba_.setLPClaimedHelper(someone, 1e10);
        assertEq(lba_.lpClaimed(someone), 1e10, "After claim it should be 1e10");
    }

    /** ----------------------------------
     * ! Busines logic
     * ----------------------------------- */

    /**
     * @notice GIVEN: LPs are not claimed yet
     * @notice  WHEN: user calls this function
     * @notice  THEN: energy amount is returned and not zero
     */
    function test_getRemainingLBAEnergy_happy_path() public skip(false) {
        vm.startPrank(address(someone));
        uint256 energy = lbaConverter_.getRemainingLBAEnergy(someone, threeDaysAgo, oneDayAgo);
        assertEq(energy, 1e12 * 2, "Should be 1e12 * 2 days");
    }

    /**
     * @notice GIVEN: LPs are already claimed
     * @notice  WHEN: user calls this function
     * @notice  THEN: energy amount should be zero
     */

    function test_getRemainingLBAEnergy_already_claimed() public skip(false) {
        vm.startPrank(address(someone));
        uint256 lpAmount = lba_.claimableLPAmount(someone);
        assertEq(lpAmount, 1e12, "should be 1e12");

        lba_.setLPClaimedHelper(someone, 1e10);
        assertEq(lba_.lpClaimed(someone), 1e10, "should be 1e10");
    }

    /**
     * @notice GIVEN:
     * @notice  WHEN:
     * @notice   AND:
     * @notice   AND:
     * @notice  THEN:
     * @notice   AND:
     */

    function testAsdf() public skip(true) returns (bool) {
        return false;
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

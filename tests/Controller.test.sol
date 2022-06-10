// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../contracts/Staking.sol";
import "../contracts/Staking.sol";
import "../contracts/Controller.sol";
import "../contracts/StakingStorage.sol";
import "../contracts/helpers/IStaking.sol";
import "../contracts/helpers/IConverter.sol";
import "../contracts/Converter.sol";
import "../contracts/LBAEnergyConverter.sol";
import "../contracts/EnergyStorage.sol";
import "../contracts/mocks/MockedERC20.sol";
import "../contracts/ILBA.sol";

import "ds-test/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM ASTO Time contract
 */
contract ControllerTestContract is DSTest, IStaking, Util {
    Staking staker_;
    Staking newStaker_;
    StakingStorage astoStorage_;
    StakingStorage lpStorage_;
    Controller controller_;
    MockedERC20 astoToken_;
    MockedERC20 lpToken_;
    EnergyStorage energyStorage_;
    Converter converterLogic_;
    LBAEnergyConverter lbaConverter_;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    uint256 amount = 1_234_567_890_000_000_000; // 1.23456789 ASTO
    uint256 initialBalance = 100e18;
    uint256 userBalance = 10e18;
    uint256 astoToken = 0; // tokenId

    ILBA lba = ILBA(0x6D08cF8E2dfDeC0Ca1b676425BcFCF1b0e064afA);
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
        setupTokens(); // mock tokens
        setupContracts(); // instantiate GM contracts
    }

    function setupTokens() internal {
        astoToken_ = new MockedERC20("ASTO Token", "ASTO", deployer, initialBalance);
        lpToken_ = new MockedERC20("Uniswap LP Token", "LP", deployer, initialBalance);
    }

    function setupContracts() internal {
        controller_ = new Controller(multisig);

        staker_ = new Staking(address(controller_));
        newStaker_ = new Staking(address(controller_));
        astoStorage_ = new StakingStorage(address(controller_));
        lpStorage_ = new StakingStorage(address(controller_));
        lbaConverter_ = new LBAEnergyConverter(address(controller_), lba);
        converterLogic_ = new Converter(address(controller_));
        energyStorage_ = new EnergyStorage(address(controller_));

        controller_.init(
            address(astoToken_),
            address(astoStorage_),
            address(lpToken_),
            address(lpStorage_),
            address(staker_),
            address(lbaConverter_),
            address(converterLogic_),
            address(energyStorage_)
        );
    }

    /** ----------------------------------
     * ! Admin functions
     * ----------------------------------- */

    function test_beforeAll() public view skip(true) {
        console.log("Multisig", address(multisig));
        console.log("Deployer", address(deployer));
        console.log("Controller", address(controller_));
        console.log("Staker", address(staker_));
        console.log("ASTO Token", address(astoToken_));
        console.log("LP Token", address(lpToken_));
        console.log("ASTO Storage", address(astoStorage_));
        console.log("LP Storage", address(lpStorage_));
    }

    /**
     * @notice GIVEN: new staking contract address
     * @notice  WHEN: NOT a manager calls the `upgrdadeContracts()`
     * @notice  THEN: should revert with long message about missing role
     */
    function testUpgradeContracts_wrong_role() public skip(false) {
        vm.prank(address(someone)); // someone address - 0xa847d497b38b9e11833eac3ea03921b40e6d847c
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08"
        );
        controller_.upgradeContracts(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(newStaker_),
            address(0),
            address(0),
            address(0)
        );
    }

    /**
     * @notice GIVEN: new staking contract address
     * @notice  WHEN: manager calls the `upgrdadeContracts()`
     * @notice   AND: all other contracts should not be changed
     * @notice  THEN: staking contract is changed and initialized
     */
    function testUpgradeContracts_staking_sol() public skip(false) {
        vm.prank(address(multisig));
        controller_.upgradeContracts(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(newStaker_),
            address(0),
            address(0),
            address(0)
        );
        assertEq(
            controller_.getStakingLogic(),
            address(newStaker_),
            "Controller should return new staking contract address"
        );
        assertEq(
            newStaker_.getTokenAddress(0),
            address(astoToken_),
            "New Staking contract should be properly initialized"
        );
        assertEq(
            newStaker_.getTokenAddress(1),
            address(lpToken_),
            "New Staking contract should be properly initialized"
        );

        assertEq(controller_.getAstoStorage(), address(astoStorage_), "Asto Storage should return old address");
        assertEq(controller_.getLpStorage(), address(lpStorage_), "LP Storage should return old address");
        assertEq(controller_.getLpStorage(), address(lpStorage_), "LP Storage should return old address");
        assertEq(controller_.getEnergyStorage(), address(energyStorage_), "Energy Storage should return old address");
        assertEq(controller_.getConverter(), address(converterLogic_), "Energy Storage should return old address");

        controller_.pause();
        bool isPaused = newStaker_.paused();

        assertTrue(isPaused, "Controller is assigned and has a correct role with new Staking contract");
    }

    /** ----------------------------------
     * ! Test contract modifiers
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

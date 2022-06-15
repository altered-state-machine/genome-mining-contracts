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
import "../contracts/EnergyStorage.sol";
import "../contracts/mocks/MockedERC20.sol";
import "../contracts/interfaces/ILiquidityBootstrapAuction.sol";

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM ASTO Time contract
 */
contract ControllerTestContract is DSTest, IStaking, IConverter, Util {
    Staking staker_;
    StakingStorage astoStorage_;
    StakingStorage lpStorage_;
    Controller controller_;
    MockedERC20 astoToken_;
    MockedERC20 lpToken_;
    EnergyStorage energyStorage_;
    EnergyStorage lbaEnergyStorage_;
    Converter converter_;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    uint256 amount = 1_234_567_890_000_000_000; // 1.23456789 ASTO
    uint256 initialBalance = 100e18;
    uint256 userBalance = 10e18;
    uint256 astoToken = 0; // tokenId

    ILiquidityBootstrapAuction lba = ILiquidityBootstrapAuction(0x6D08cF8E2dfDeC0Ca1b676425BcFCF1b0e064afA);
    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address deployer = address(this);
    address multisig = deployer; // for the testing we use deployer as a multisig
    address dao = deployer; // for the testing we use deployer as a dao

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
        astoStorage_ = new StakingStorage(address(controller_));
        lpStorage_ = new StakingStorage(address(controller_));
        converter_ = new Converter(address(controller_), address(lba), new Period[](0));
        energyStorage_ = new EnergyStorage(address(controller_));
        lbaEnergyStorage_ = new EnergyStorage(address(controller_));

        controller_.init(
            address(dao),
            address(astoToken_),
            address(astoStorage_),
            address(lpToken_),
            address(lpStorage_),
            address(staker_),
            address(converter_),
            address(energyStorage_),
            address(lbaEnergyStorage_)
        );
    }

    /** ----------------------------------
     * ! Admin functions
     * ----------------------------------- */

    /**
     * @notice GIVEN: new staking contract address
     * @notice  WHEN: NOT a manager calls the `upgrdadeContracts()`
     * @notice  THEN: should revert with long message about missing role
     */
    function test_upgradeContracts_wrong_role() public skip(false) {
        Staking newContract_ = new Staking(address(controller_));
        vm.prank(address(someone)); // someone address - 0xa847d497b38b9e11833eac3ea03921b40e6d847c
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0x3b5d4cc60d3ec3516ee8ae083bd60934f6eb2a6c54b1229985c41bfb092b2603"
        );
        controller_.upgradeContracts(
            address(0),
            address(0),
            address(0),
            address(0),
            address(newContract_),
            address(0),
            address(0),
            address(0)
        );
    }

    /**
     * @notice GIVEN: new astoStorage contract address
     * @notice  WHEN: manager calls the `upgrdadeContracts()`
     * @notice   AND: all other contracts should not be changed
     * @notice  THEN: staking contract is changed and initialized
     */
    function test_upgradeContracts_astoStorage_sol() public skip(false) {
        StakingStorage newContract_ = new StakingStorage(address(controller_));

        vm.prank(address(multisig));
        controller_.upgradeContracts(
            address(0), // asto token
            address(newContract_), // astoStorage
            address(0), // lpToken
            address(0), // lpStorage
            address(0), // stakingLogic
            address(0), // converterLogic
            address(0), // energyStorage
            address(0) // lbaEnergyStorage
        );

        // Checking controller
        assertEq(controller_.getAstoStorage(), address(newContract_), "Controller should return new contract address");

        // Checking contract roles
        assertTrue(newContract_.hasRole(CONSUMER_ROLE, address(staker_)), "Should have set a proper consumer");
        assertTrue(newContract_.hasRole(CONTROLLER_ROLE, address(controller_)), "Should have set a proper controller");

        // Checking functions work
        assertEq(newContract_.getUserLastStakeId(someone), 0);
        assertTrue(!newContract_.paused(), "Storage contract is not paused");
    }

    /**
     * @notice GIVEN: new lpStorage contract address
     * @notice  WHEN: manager calls the `upgrdadeContracts()`
     * @notice   AND: all other contracts should not be changed
     * @notice  THEN: staking contract is changed and initialized
     */
    function test_upgradeContracts_lpStorage_sol() public skip(false) {
        StakingStorage newContract_ = new StakingStorage(address(controller_));

        vm.prank(address(multisig));
        controller_.upgradeContracts(
            address(0), // asto token
            address(0), // astoStorage
            address(0), // lpToken
            address(newContract_), // lpStorage
            address(0), // stakingLogic
            address(0), // converterLogic
            address(0), // energyStorage
            address(0) // lbaEnergyStorage
        );

        // Checking controller
        assertEq(controller_.getLpStorage(), address(newContract_), "Controller should return new contract address");

        // Checking contract roles
        assertTrue(newContract_.hasRole(CONSUMER_ROLE, address(staker_)), "Should have set a proper consumer");
        assertTrue(newContract_.hasRole(CONTROLLER_ROLE, address(controller_)), "Should have set a proper controller");

        // Checking functions work
        assertEq(newContract_.getUserLastStakeId(someone), 0, "No stakes");
        assertTrue(!newContract_.paused(), "Storage contract is not paused");
    }

    /**
     * @notice GIVEN: new staking contract address
     * @notice  WHEN: manager calls the `upgrdadeContracts()`
     * @notice   AND: all other contracts should not be changed
     * @notice  THEN: staking contract is changed and initialized
     */
    function test_upgradeContracts_staking_sol() public skip(false) {
        Staking newContract_ = new Staking(address(controller_));
        vm.prank(address(multisig));
        controller_.upgradeContracts(
            address(0), // asto token
            address(0), // astoStorage
            address(0), // lpToken
            address(0), // lpStorage
            address(newContract_), // stakingLogic
            address(0), // converterLogic
            address(0), // energyStorage
            address(0) // lbaEnergyStorage
        );

        // Checking controller
        assertEq(controller_.getStakingLogic(), address(newContract_), "Controller should return new contract address");

        // Checking contract roles
        assertTrue(newContract_.hasRole(CONTROLLER_ROLE, address(controller_)), "Should have set a proper controller");
        assertTrue(newContract_.hasRole(DAO_ROLE, address(dao)), "Should have a proper DAO");

        // Checking getters
        assertEq(controller_.getStakingLogic(), address(newContract_));
        assertEq(controller_.getAstoStorage(), address(astoStorage_));
        assertEq(controller_.getLpStorage(), address(lpStorage_));
        assertEq(controller_.getLpStorage(), address(lpStorage_));
        assertEq(controller_.getEnergyStorage(), address(energyStorage_));
        assertEq(controller_.getLBAEnergyStorage(), address(lbaEnergyStorage_));
        assertEq(controller_.getConverterLogic(), address(converter_));

        // Checking functions work
        assertEq(newContract_.getTokenAddress(0), address(astoToken_));
        assertEq(newContract_.getTokenAddress(1), address(lpToken_));
        assertTrue(newContract_.paused());
        controller_.unpause();
        assertTrue(!newContract_.paused());
    }

    /**
     * @notice GIVEN: new Converter contract address
     * @notice  WHEN: manager calls the `upgrdadeContracts()`
     * @notice   AND: all other contracts should not be changed
     * @notice  THEN: staking contract is changed and initialized
     */
    function test_upgradeContracts_converter_sol() public skip(false) {
        Converter newContract_ = new Converter(address(controller_), address(lba), new Period[](0));
        vm.prank(address(multisig));

        controller_.upgradeContracts(
            address(0), // asto token
            address(0), // astoStorage
            address(0), // lpToken
            address(0), // lpStorage
            address(0), // stakingLogic
            address(newContract_), // converterLogic
            address(0), // energyStorage
            address(0) // lbaEnergyStorage
        );
        // Checking controller
        assertEq(
            controller_.getConverterLogic(),
            address(newContract_),
            "Controller should return new contract address"
        );

        // Checking contract roles
        // !ATTN: until minting contract isn'set, the consumer of Converter is a Controller
        assertTrue(newContract_.hasRole(CONSUMER_ROLE, address(controller_)), "Should have set a proper consumer");
        assertTrue(newContract_.hasRole(CONTROLLER_ROLE, address(controller_)), "Should have set a proper controller");
        assertTrue(newContract_.hasRole(DAO_ROLE, address(dao)), "Should have a proper DAO");
        assertTrue(newContract_.hasRole(MULTISIG_ROLE, address(multisig)), "Should have a proper Multisig");

        // Checking getters
        assertTrue(controller_.getConverterLogic() != address(converter_), "Shouldn't be an old converter");
        assertEq(controller_.getConverterLogic(), address(newContract_), "Should be a new converter");

        // Checking functions work
        assertEq(newContract_.getConsumedEnergy(someone), 0, "No energy used yet");
        assertTrue(newContract_.paused());
        controller_.unpause();
        assertTrue(!newContract_.paused());
    }

    /**
     * @notice GIVEN: new Converter contract address
     * @notice  WHEN: manager calls the `upgrdadeContracts()`
     * @notice   AND: all other contracts should not be changed
     * @notice  THEN: staking contract is changed and initialized
     */
    function test_upgradeContracts_multiple_contracts_at_once() public skip(false) {
        Converter newConverter_ = new Converter(address(controller_), address(lba), new Period[](0));
        Staking newStaker_ = new Staking(address(controller_));
        vm.prank(address(multisig));

        controller_.upgradeContracts(
            address(0), // asto token
            address(0), // astoStorage
            address(0), // lpToken
            address(0), // lpStorage
            address(newStaker_), // stakingLogic
            address(newConverter_), // converterLogic
            address(0), // energyStorage
            address(0) // lbaEnergyStorage
        );

        // Checking controller
        assertEq(
            controller_.getConverterLogic(),
            address(newConverter_),
            "Controller should return new contract address"
        );

        // Checking contract roles
        // !ATTN: until minting contract isn'set, the consumer of Converter is a Controller
        assertTrue(newConverter_.hasRole(CONSUMER_ROLE, address(controller_)), "Should have set a proper consumer");
        assertTrue(newConverter_.hasRole(CONTROLLER_ROLE, address(controller_)), "Should have set a proper controller");
        assertTrue(newStaker_.hasRole(CONTROLLER_ROLE, address(controller_)), "Should have set a proper controller");

        // newContract.getConsumedEnergy()
    }

    /**
     * @notice GIVEN: new energy storage contract address
     * @notice  WHEN: manager calls the `upgrdadeContracts()`
     * @notice   AND: all other contracts should not be changed
     * @notice  THEN: staking contract is changed and initialized
     */
    function test_upgradeContracts_energyStorage_sol() public skip(false) {
        EnergyStorage newContract_ = new EnergyStorage(address(controller_));
        vm.prank(address(multisig));
        controller_.upgradeContracts(
            address(0), // asto token
            address(0), // astoStorage
            address(0), // lpToken
            address(0), // lpStorage
            address(0), // stakingLogic
            address(0), // converterLogic
            address(newContract_), // energyStorage
            address(0) // lbaEnergyStorage
        );

        // Checking controller
        assertEq(
            controller_.getEnergyStorage(),
            address(newContract_),
            "Controller should return new contract address"
        );

        // Checking contract roles
        assertTrue(newContract_.hasRole(CONSUMER_ROLE, address(converter_)), "Should have set a proper consumer");
        assertTrue(newContract_.hasRole(CONTROLLER_ROLE, address(controller_)), "Should have set a proper controller");
    }

    /**
     * @notice GIVEN: new lbaStorage contract address
     * @notice  WHEN: manager calls the `upgrdadeContracts()`
     * @notice   AND: all other contracts should not be changed
     * @notice  THEN: staking contract is changed and initialized
     */
    function test_upgradeContracts_lbaStorage_sol() public skip(false) {
        EnergyStorage newContract_ = new EnergyStorage(address(controller_));
        vm.prank(address(multisig));
        controller_.upgradeContracts(
            address(0), // asto token
            address(0), // astoStorage
            address(0), // lpToken
            address(0), // lpStorage
            address(0), // stakingLogic
            address(0), // converterLogic
            address(0), // energyStorage
            address(newContract_) // lbaEnergyStorage
        );

        // Checking controller
        assertEq(
            controller_.getLBAEnergyStorage(),
            address(newContract_),
            "Controller should return new contract address"
        );

        // Checking contract roles
        assertTrue(newContract_.hasRole(CONSUMER_ROLE, address(converter_)), "Should have set a proper consumer");
        assertTrue(newContract_.hasRole(CONTROLLER_ROLE, address(controller_)), "Should have set a proper controller");
    }

    /**
     * @notice GIVEN: new Controller contract address
     * @notice  WHEN: manager calls the `upgrdadeContracts()`
     * @notice   AND: all other contracts should not be changed
     * @notice  THEN: staking contract is changed and initialized
     */
    function test_upgradeContracts_setController() public skip(false) {
        vm.startPrank(address(multisig));
        Controller newContract_ = new Controller(multisig);

        // Old controller should set a New Controller before initialisig a new contract
        controller_.setController(address(newContract_));

        newContract_.init(
            address(dao),
            address(astoToken_),
            address(astoStorage_),
            address(lpToken_),
            address(lpStorage_),
            address(staker_),
            address(converter_),
            address(energyStorage_),
            address(lbaEnergyStorage_)
        );

        assertEq(
            newContract_.getStakingLogic(),
            address(staker_),
            "New Controller should return staking contract address"
        );

        // Checking controller
        assertEq(newContract_.getController(), address(newContract_), "Controller should return new contract address");

        // Checking contract roles
        assertTrue(newContract_.hasRole(DAO_ROLE, dao), "Should have set a proper DAO");
        assertTrue(newContract_.hasRole(MULTISIG_ROLE, multisig), "Should have set a proper Multisig");

        // Checking getters
        assertEq(newContract_.getAstoStorage(), address(astoStorage_), "should return proper address");
        assertEq(newContract_.getLpStorage(), address(lpStorage_), "should return proper address");
        assertEq(newContract_.getLpStorage(), address(lpStorage_), "should return proper address");
        assertEq(newContract_.getEnergyStorage(), address(energyStorage_), "should return proper address");
        assertEq(newContract_.getLBAEnergyStorage(), address(lbaEnergyStorage_), "should return proper address");
        assertEq(newContract_.getConverterLogic(), address(converter_), "should return proper address");
    }

    /**
     * @notice GIVEN: new Multisig contract address
     * @notice  WHEN: DAO calls the `setMultisig()`
     * @notice  THEN: converter's Multisig role should be set
     * @notice   AND: controller's variable _multisig should be updated
     */
    function test_upgradeContracts_setMultisig() public skip(false) {
        vm.startPrank(address(multisig));

        controller_.setMultisig(address(lba)); // let's make this contract a multisig

        // Checking controller
        assertEq(controller_.getMultisig(), address(lba), "Controller's variable updated");

        // Checking contract roles
        assertTrue(converter_.hasRole(MULTISIG_ROLE, address(lba)), "Should have set a proper Multisig");
    }

    /**
     * @notice GIVEN: new Dao contract address
     * @notice  WHEN: old DAO calls the `setDao()`
     * @notice  THEN: converter's DAO_ROLE should be set
     * @notice   AND: controller's variable `_dao` should be updated
     */
    function test_upgradeContracts_setDao() public skip(false) {
        vm.startPrank(multisig);

        controller_.setDao(address(lba)); // let's make this contract a DAO

        // Checking controller
        assertEq(controller_.getDao(), address(lba), "Controller's variable updated");

        // Checking contract roles
        assertTrue(!converter_.hasRole(DAO_ROLE, address(this)), "Should remove an old DAO");
        assertTrue(converter_.hasRole(DAO_ROLE, address(lba)), "Should have set a proper DAO");
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

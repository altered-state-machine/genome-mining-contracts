// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../contracts/helpers/PermissionControl.sol";

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the PermissionControl contract
 */
contract PermissionControlTest is DSTest, PermissionControl {
    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address another = 0x7d7bd5e3a6f374CAAc008e3a33949aDa5fC1cc03;
    address deployer = address(this);

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        setupWallets();
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings
        vm.deal(another, 1); // gas spendings
    }

    /** ----------------------------------
     * ! Logic
     * ----------------------------------- */

    /**
     * @notice GIVEN: role and address
     * @notice  WHEN: address already have the role
     * @notice  THEN: should clear the role
     */
    function testClearRole_with_existing_role() public skip(false) {
        _grantRole(CONSUMER_ROLE, deployer);
        assertEq(getRoleMemberCount(CONSUMER_ROLE), 1);
        assertTrue(hasRole(CONSUMER_ROLE, deployer));

        _clearRole(CONSUMER_ROLE);
        assertTrue(!hasRole(CONSUMER_ROLE, deployer));
    }

    /**
     * @notice GIVEN: role and address
     * @notice  WHEN: multiple addresses have the role
     * @notice  THEN: revoke the role to the all old addresses
     */
    function testClearRole_will_revoke_all_role_members() public skip(false) {
        _grantRole(CONSUMER_ROLE, someone);
        _grantRole(CONSUMER_ROLE, another);
        assertTrue(hasRole(CONSUMER_ROLE, someone));
        assertTrue(hasRole(CONSUMER_ROLE, another));
        assertEq(getRoleMemberCount(CONSUMER_ROLE), 2);

        _clearRole(CONSUMER_ROLE);
        assertTrue(!hasRole(CONSUMER_ROLE, someone));
        assertTrue(!hasRole(CONSUMER_ROLE, another));
        assertEq(getRoleMemberCount(CONSUMER_ROLE), 0);
    }

    function testAddConsumer_from_controller() public skip(false) {
        _grantRole(CONTROLLER_ROLE, someone);

        vm.prank(someone);
        this.addConsumer(another);

        assertTrue(hasRole(CONSUMER_ROLE, another));
    }

    function testAddConsumer_from_multisig() public skip(false) {
        _grantRole(MULTISIG_ROLE, someone);

        vm.prank(someone);
        this.addConsumer(another);

        assertTrue(hasRole(CONSUMER_ROLE, another));
    }

    function testAddConsumer_from_wrong_address() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(AccessDenied.selector, MISSING_ROLE));
        this.addConsumer(another);
    }

    function testRemoveConsumer_from_controller() public skip(false) {
        _grantRole(CONTROLLER_ROLE, someone);

        vm.startPrank(someone);
        this.addConsumer(another);
        assertTrue(hasRole(CONSUMER_ROLE, another));

        this.removeConsumer(another);
        assertTrue(!hasRole(CONSUMER_ROLE, another));
    }

    function testRemoveConsumer_from_multisig() public skip(false) {
        _grantRole(MULTISIG_ROLE, someone);

        vm.startPrank(someone);
        this.addConsumer(another);
        assertTrue(hasRole(CONSUMER_ROLE, another));

        this.removeConsumer(another);
        assertTrue(!hasRole(CONSUMER_ROLE, another));
    }

    function testRemoveConsumer_from_wrong_address() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(AccessDenied.selector, MISSING_ROLE));
        this.removeConsumer(another);
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

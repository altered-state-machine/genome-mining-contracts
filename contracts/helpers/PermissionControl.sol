// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev ASM Genome Mining - PermissionControl contract
 */

bytes32 constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
bytes32 constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");
bytes32 constant DAO_ROLE = keccak256("DAO_ROLE");
bytes32 constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

contract PermissionControl is AccessControl {
    /**
     * @dev Update `role` from the sender to `_newAddress`.
     * @dev Internal function without access restriction.
     */
    function _updateRole(bytes32 role, address _newAddress) internal {
        _revokeRole(role, msg.sender);
        _grantRole(role, _newAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @dev ASM Genome Mining - PermissionControl contract
 */

bytes32 constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
bytes32 constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");
bytes32 constant DAO_ROLE = keccak256("DAO_ROLE");
bytes32 constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

contract PermissionControl is AccessControlEnumerable {
    /**
     * @dev Update `role` from the sender to `newAddress`.
     * @dev Internal function without access restriction.
     */
    function _updateRole(bytes32 role, address newAddress) internal {
        address oldAddress = getRoleMember(role, 0);
        _revokeRole(role, oldAddress);
        _grantRole(role, newAddress);
    }
}

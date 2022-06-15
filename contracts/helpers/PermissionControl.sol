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
     * @dev Update `role` to `newAddress`. It will revoke the old role assignments as well.
     * @dev Internal function without access restriction.
     */
    function _updateRole(bytes32 role, address newAddress) internal {
        uint256 count = getRoleMemberCount(role);
        for (uint256 i = count; i > 0; i--) {
            _revokeRole(role, getRoleMember(role, i - 1));
        }

        _grantRole(role, newAddress);
    }
}

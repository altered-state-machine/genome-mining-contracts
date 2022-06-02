// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev ASM Genome Mining - PermissionControl contract
 */
contract PermissionControl is AccessControl {
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant STAKER_ROLE = keccak256("STAKER_ROLE");
    bytes32 public constant CONVERTER_ROLE = keccak256("CONVERTER_ROLE");

    /**
     * @dev Update `role` from the sender to `_newAddress`.
     *
     * Internal function without access restriction.
     */
    function _updateRole(bytes32 role, address _newAddress) internal {
        _revokeRole(role, msg.sender);
        _grantRole(role, _newAddress);
    }
}

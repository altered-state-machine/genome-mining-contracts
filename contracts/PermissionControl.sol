// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev ASM Genome Mining - PermissionControl contract
 */
contract PermissionControl is AccessControl {
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CONVERTER_ROLE = keccak256("CONVERTER_ROLE");

    /**
     * @dev Update `role` from the sender to `_newAddress`.
     *
     * Internal function without access restriction.
     */
    function _updateRole(bytes32 role, address _newAddress) internal {
        _setupRole(role, _newAddress);
        _revokeRole(role, msg.sender);
    }

    /**
     * @dev Check if `_regitry` has a REGISTRY_ROLE role.
     */
    function isRegistry(address _registry) public returns (bool) {
        return hasRole(_registry, REGISTRY_ROLE);
    }

    /**
     * @dev Check if `_manager` has a MANAGER_ROLE role.
     */
    function isManager(address _manager) public returns (bool) {
        return hasRole(_manager, MANAGER_ROLE);
    }

    /**
     * @dev Check if `_converter` has a CONVERTER_ROLE role.
     */
    function isConverter(address _converter) public returns (bool) {
        return hasRole(_converter, CONVERTER_ROLE);
    }
}

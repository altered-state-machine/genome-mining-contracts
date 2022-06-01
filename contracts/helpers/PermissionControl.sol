// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev ASM Genome Mining - PermissionControl contract
 */
contract PermissionControl is AccessControl {
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");
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

    /**
     * @dev Check if `_regitry` has a REGISTRY_ROLE role.
     */
    function isRegistry(address _registry) public view returns (bool) {
        return hasRole(REGISTRY_ROLE, _registry);
    }

    /**
     * @dev Check if `_manager` has a MANAGER_ROLE role.
     */
    function isManager(address _manager) public view returns (bool) {
        return hasRole(MANAGER_ROLE, _manager);
    }

    /**
     * @dev Check if `_converter` has a CONVERTER_ROLE role.
     */
    function isConverter(address _converter) public view returns (bool) {
        return hasRole(CONVERTER_ROLE, _converter);
    }

    function updateManager(address _manager) external onlyRole(REGISTRY_ROLE) {
        _updateRole(MANAGER_ROLE, _manager);
    }

    function updateRegistry(address _registry) external onlyRole(REGISTRY_ROLE) {
        _updateRole(REGISTRY_ROLE, _registry);
    }

    function updateConverter(address _converter) external onlyRole(REGISTRY_ROLE) {
        _updateRole(CONVERTER_ROLE, _converter);
    }
}

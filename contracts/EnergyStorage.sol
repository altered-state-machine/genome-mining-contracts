// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

// TODO update comments

/**
 * @dev ASM Genome Mining - Energy Storage contract
 *
 * Store consumed energy amount for each address.
 * The contract is managed by a Controller contract.
 */
contract EnergyStorage is Util, Pausable, PermissionControl {
    bool private initialized = false;

    mapping(address => uint256) public consumedAmount;

    constructor(address controller) {
        if (!_isContract(controller)) revert ContractError(INVALID_CONTROLLER);
        _grantRole(CONTROLLER_ROLE, controller);
        _pause();
    }

    /**
     * @notice Update balance for `addr` on period `periodId`
     * @notice Function can be called only manager
     *
     */
    function increaseConsumedAmount(address addr, uint256 amount) external whenNotPaused onlyRole(CONVERTER_ROLE) {
        if (address(addr) == address(0)) revert ContractError(WRONG_ADDRESS);

        consumedAmount[addr] += amount;

        // TODO emit event
    }

    /** ----------------------------------
     * ! Admin functions
     * ----------------------------------- */

    function init(address converterLogic) external onlyRole(CONTROLLER_ROLE) {
        require(!initialized, "The contract has already been initialized.");
        if (!_isContract(converterLogic)) revert ContractError(INVALID_CONVERTER_LOGIC);

        _setupRole(CONVERTER_ROLE, converterLogic);
        _unpause();
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }

    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(CONTROLLER_ROLE, newController);
    }
}

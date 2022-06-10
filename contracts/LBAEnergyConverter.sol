// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Staking.sol";
import "./EnergyStorage.sol";
import "./helpers/IConverter.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";
import "./ILBA.sol";

/**
 * @dev ASM Genome Mining - LBA Converter Logic contract
 * @notice Energy calculation and conversion from the LBA LP tokens.
 */
contract LBAEnergyConverter is Util, PermissionControl, Pausable {
    bool private _initialized = false;

    /**
     * @dev rinkeby: 0x6D08cF8E2dfDeC0Ca1b676425BcFCF1b0e064afA
     * @dev mainnet: 0x46C1BFAe04c19aA6b114A0FC3Ef78d19C9256763
     */
    ILBA private _lba;

    constructor(address controller, ILBA lba) {
        if (!_isContract(controller)) revert ContractError(INVALID_CONTROLLER);
        _lba = ILBA(lba);
        _grantRole(CONTROLLER_ROLE, controller);
        _grantRole(USER_ROLE, controller);
        _grantRole(CONVERTER_ROLE, controller);
        _pause();
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    mapping(address => uint256) public usedLBAEnergyPerUser;

    function _calculateAvailableEnergy(
        address addr,
        uint256 startTime,
        uint256 endTime
    ) private view returns (uint256) {
        uint256 period = (endTime - startTime) / SECONDS_PER_DAY;
        uint256 lpAmount = _lba.claimableLPAmount(addr);
        return period * lpAmount;
    }

    function getRemainingLBAEnergy(
        address addr,
        uint256 startTime,
        uint256 endTime
    ) public view returns (uint256) {
        uint256 availableEnergy = _calculateAvailableEnergy(addr, startTime, endTime);
        if (availableEnergy > 0) return availableEnergy - usedLBAEnergyPerUser[addr];
        else return 0;
    }

    function useLBAEnergy(
        address addr,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    ) public onlyRole(CONVERTER_ROLE) returns (uint256) {
        uint256 usedEnergy = usedLBAEnergyPerUser[addr];
        uint256 remainingEnergy = getRemainingLBAEnergy(addr, startTime, endTime);

        if (remainingEnergy > 0) usedLBAEnergyPerUser[addr] = usedEnergy + amount;
        else revert CalculationsError(NOT_ENOUGH_ENERGY);

        return remainingEnergy - amount;
    }

    /** ----------------------------------
     * ! Administration          | MANAGER
     * ----------------------------------- */

    function setUser(address addr) external onlyRole(MANAGER_ROLE) {
        _updateRole(USER_ROLE, addr);
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Initialize the contract:
     * @dev only controller is allowed to call this function
     *
     * @param manager The manager contract address
     * @param converter The Main Converter contract address
     */
    function init(address manager, address converter) external onlyRole(CONTROLLER_ROLE) {
        if (_initialized) revert ContractError(ALREADY_INITIALIZED);

        if (!_isContract(converter)) revert ContractError(INVALID_ENERGY_STORAGE);

        _grantRole(CONVERTER_ROLE, converter);
        _grantRole(MANAGER_ROLE, manager);
        _unpause();

        _initialized = true;
    }

    /**
     * @dev Update the manager contract address
     * @dev only manager is allowed to call this function
     */
    function setManager(address newManager) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(MANAGER_ROLE, newManager);
    }

    /**
     * @dev Update the controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(CONTROLLER_ROLE, newController);
    }

    /**
     * @dev Pause the contract
     * @dev only controller is allowed to call this function
     */
    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * @dev only controller is allowed to call this function
     */
    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IConverter.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

// TODO comments

/**
 * @dev ASM Genome Mining - Converter Logic contract
 */
contract Converter is IConverter, TimeConstants, Util, PermissionControl, Pausable {
    bool private initialized = false;

    uint256 public periodIdCounter = 0;
    // PeriodId start from 1
    mapping(uint256 => Period) public periods;

    constructor(address controller) {
        if (!_isContract(controller)) revert ContractError(INVALID_CONTROLLER);
        _grantRole(CONTROLLER_ROLE, controller);
        _initPeriods();
        _pause();
    }

    function _initPeriods() internal {
      // TODO add 3 periods
    }

    function getPeriod(uint256 periodId) public view returns (Period memory) {
      if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);
      return periods[periodId]
    }

    /**
     * @notice Get the current periodId based on current timestamp
     *
     * @return current periodId
     */
    function getCurrentPeriodId() public view returns (uint256) {
        for (uint256 index = 1; index <= periodIdCounter; index++) {
            Period storage p = periods[index];
            if (currentTime() >= uint256(p.startTime) && currentTime() < uint256(p.startTime) + uint256(p.duration)) {
                return index;
            }
        }

        return 0;
    }

    function getCurrentPeriod() public view returns (Period memory) {
      return periods[getCurrentPeriodId()];
    }

    /**
     * @notice Setup new period
     * @notice Function can be called only manager
     *
     */
    function _addPeriod(
        uint128 startTime,
        uint128 endTime,
        address[] memory tokens,
        uint256[] memory multipliers
    ) internal {
        if (tokens.length != multipliers.length) revert ContractError(WRONG_ARGUMENTS);

        Period storage p = periods[++periodIdCounter];
        p.startTime = startTime;
        p.endTime= endTime;
        for (uint256 i = 0; i < tokens.length; i++) {
            p.multipliers[tokens[i]] = multipliers[i];
        }
    }

    function addPeriod(
        uint128 startTime,
        uint128 endTime,
        address[] memory tokens,
        uint256[] memory multipliers
    ) external whenNotPaused onlyRole(ONLY_MANAGER) {
      _addPeriod(startTime, endTime, tokens, multipliers)
    }

    /**
     * @notice Calculate the available energy for `addr`
     *
     * @param addr - wallet address to calculate
     * @return Energy avaiable
     */
    function getEnergy(address addr) external returns (uint256) {}

    /**
     * @notice Estimate energy can be generated per day for all stakes
     *
     * @return Energy can be generated
     */
    function getEstimatedEnergyPerDay() public view returns (uint256) {}

    /**
     * @notice Get total energy balance in storage contract
     *
     * @return Total energy balance
     */
    function getTotalEnergy() public view returns (uint256) {}

    /**
     * @notice Get user share of the whole energy pool
     *
     * @param periodId - the periodId to calculate
     * @return Share number
     */
    function getPeriodShare(uint256 periodId) public view returns (uint256) {}

    /**
     * @notice Consume energy
     *
     * @param recipient - the contract address to receive the energy
     * @param amount - the amount of energy to transfer
     */
    function useEnergy(uint256 amount) external {}

    /**
     * @notice Get the current periodId based on current timestamp
     * @dev Can be overridden by child contracts
     *
     * @return current timestamp
     */
    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /** ----------------------------------
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @param registry Registry contract address
     * @param energyStorage Energy storage contract address
     * @param stakingStorage Staking storage contract address
     */
    function init(
        address energyStorage,
        address stakingLogic,
        address manager,
    ) external onlyRole(CONTROLLER_ROLE) {
        require(!initialized, "The contract has already been initialized.");

        if (!_isContract(energyStorage)) revert ContractError(INVALID_CONVERTER_STORAGE);
        if (!_isContract(stakingLogic)) revert ContractError(INVALID_STAKING_LOGIC);

        _unpause();

        initialized = true;

        _grantRole(MANAGER_ROLE, manager);

        // TODO setup Storage contracts
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner(CONTROLLER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }
}

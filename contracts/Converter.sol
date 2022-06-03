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

/**
 * @dev ASM Genome Mining - Converter Logic contract
 *
 * This contracts provides functionality for ASTO Energy calculation and conversion.
 * Energy is calculated based on the token staking history from staking contract and multipliers pre-defined for ASTO and LP tokens.
 * Eenrgy can be consumed on multiple purposes.
 */
contract Converter is IConverter, IStaking, TimeConstants, Util, PermissionControl, Pausable {
    using SafeMath for uint256;

    bool private initialized = false;

    uint256 public periodIdCounter = 0;
    // PeriodId start from 1
    mapping(uint256 => Period) public periods;

    Staking public stakingLogic_;
    EnergyStorage public energyStorage_;

    uint256 public constant ASTO_TOKEN_ID = 0;
    uint256 public constant LP_TOKEN_ID = 1;

    constructor(address controller, Period[] memory _periods) {
        if (!_isContract(controller)) revert ContractError(INVALID_CONTROLLER);
        _grantRole(CONTROLLER_ROLE, controller);
        _initPeriods(_periods);
        _pause();
    }

    /**
     * @dev Initialize pre-defined periods
     */
    function _initPeriods(Period[] memory _periods) internal {
        for (uint256 i = 0; i < _periods.length; i++) {
            _addPeriod(_periods[i]);
        }
    }

    /**
     * @dev Get period data by period id `periodId`
     *
     * @param periodId The id of period to get
     * @return a Period struct
     */
    function getPeriod(uint256 periodId) public view returns (Period memory) {
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);
        return periods[periodId];
    }

    /**
     * @notice Get the current period id based on current timestamp
     *
     * @return current periodId
     */
    function getCurrentPeriodId() public view returns (uint256) {
        for (uint256 index = 1; index <= periodIdCounter; index++) {
            Period memory p = periods[index];
            if (currentTime() >= uint256(p.startTime) && currentTime() < uint256(p.endTime)) {
                return index;
            }
        }
        return 0;
    }

    /**
     * @notice Get the current period based on current timestamp
     *
     * @return current period data
     */
    function getCurrentPeriod() public view returns (Period memory) {
        return periods[getCurrentPeriodId()];
    }

    /**
     * @dev Add a new period
     * @dev This is an internal function
     *
     * @param period The period instance to add
     */
    function _addPeriod(Period memory period) internal {
        periods[++periodIdCounter] = period;
    }

    /**
     * @dev Add a new period
     * @dev Only manager contract has the permission to call this function
     *
     * @param period The period instance to add
     */
    function addPeriod(Period memory period) external whenNotPaused onlyRole(MANAGER_ROLE) {
        _addPeriod(period);
    }

    /**
     * @dev Update a period
     * @dev This is an internal function
     *
     * @param periodId The period id to update
     * @param period The period data to update
     */
    function _updatePeriod(uint256 periodId, Period memory period) internal {
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);
        periods[periodId] = period;
    }

    /**
     * @dev Update a period
     * @dev Only manager contract has the permission to call this function
     *
     * @param periodId The period id to update
     * @param period The period data to update
     */
    function updatePeriod(uint256 periodId, Period memory period) external whenNotPaused onlyRole(MANAGER_ROLE) {
        _updatePeriod(periodId, period);
    }

    /**
     * @dev Get consumed energy amount for address `addr
     *
     * @param addr The wallet address to get consumed energy for
     * @return Consumed energy amount
     */
    function getConsumedEnergy(address addr) public view returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        return energyStorage_.consumedAmount(addr);
    }

    /**
     * @dev Calculate the energy for `addr` based on the staking history  before the endTime of specified period
     *
     * @param addr The wallet address to calculated for
     * @param periodId The period id for energy calculation
     * @return energy amount
     */
    function calculateEnergy(address addr, uint256 periodId) public view returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);

        Period memory period = getPeriod(periodId);

        Stake[] memory astoHistory = stakingLogic_.getHistory(ASTO_TOKEN_ID, addr, period.endTime);
        Stake[] memory lpHistory = stakingLogic_.getHistory(LP_TOKEN_ID, addr, period.endTime);

        uint256 astoEnergyAmount = _calculateEnergyForToken(astoHistory, period.astoMultiplier);
        uint256 lpEnergyAmount = _calculateEnergyForToken(lpHistory, period.lpMultiplier);

        return (astoEnergyAmount + lpEnergyAmount);
    }

    /**
     * @dev Calculate the energy for specific staked token
     *
     * @param history The staking history for the staked token
     * @param multiplier The multiplier for staked token
     * @return total energy amount for the token
     */
    function _calculateEnergyForToken(Stake[] memory history, uint256 multiplier) internal view returns (uint256) {
        uint256 total = 0;
        uint256 prevStakedAmount = 0;
        for (uint256 i = 0; i < history.length; i++) {
            if (currentTime() < history[i].time) continue;

            uint256 elapsedTime = currentTime().sub(history[i].time);
            uint256 elapsedDays = elapsedTime.div(SECONDS_PER_DAY);
            total = total.add(elapsedDays.mul(history[i].amount.sub(prevStakedAmount)).mul(multiplier));
            prevStakedAmount = history[i].amount;
        }
        return total;
    }

    /**
     * @dev Get the energy amount available for address `addr`
     *
     * @param addr The wallet address to get energy for
     * @param periodId The period id for energy calculation
     * @return Energy amount available
     */
    function getEnergy(address addr, uint256 periodId) public returns (uint256) {
        return calculateEnergy(addr, periodId) - getConsumedEnergy(addr);
    }

    /**
     * @dev Consume energy generated before the endTime of period `periodId`
     *
     * @param addr The wallet address to consume from
     * @param periodId The period id for energy consumption
     * @param amount The amount of energy to consume
     */
    function useEnergy(
        address addr,
        uint256 periodId,
        uint256 amount
    ) external {
        // TODO check permission
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);
        if (amount > getEnergy(addr, periodId)) revert InvalidInput(WRONG_AMOUNT);

        energyStorage_.increaseConsumedAmount(addr, amount);
    }

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
     * ! Admin functions
     * ----------------------------------- */

    /**
     * @dev Initialize the contract:
     * @dev only controller is allowed to call this function
     *
     * @param manager The manager contract address
     * @param energyStorage The energy storage contract address
     * @param stakingLogic The staking logic contrct address
     */
    function init(
        address manager,
        address energyStorage,
        address stakingLogic
    ) external onlyRole(CONTROLLER_ROLE) {
        require(!initialized, "The contract has already been initialized.");

        if (!_isContract(energyStorage)) revert ContractError(INVALID_ENERGY_STORAGE);
        if (!_isContract(stakingLogic)) revert ContractError(INVALID_STAKING_LOGIC);

        stakingLogic_ = Staking(stakingLogic);
        energyStorage_ = EnergyStorage(energyStorage);

        _grantRole(MANAGER_ROLE, manager);
        _unpause();
        initialized = true;
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

    /**
     * @dev Update the controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(CONTROLLER_ROLE, newController);
    }

    /**
     * @dev Update the manager contract address
     * @dev only manager is allowed to call this function
     */
    function setManager(address newManager) external onlyRole(MANAGER_ROLE) {
        _updateRole(MANAGER_ROLE, newManager);
    }
}

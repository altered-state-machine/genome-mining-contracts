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
import "./interfaces/ILiquidityBootstrapAuction.sol";

/**
 * @dev ASM Genome Mining - Converter Logic contract
 *
 * This contracts provides functionality for ASTO Energy calculation and conversion.
 * Energy is calculated based on the token staking history from staking contract and multipliers pre-defined for ASTO and LP tokens.
 * Eenrgy can be consumed on multiple purposes.
 */
contract Converter is IConverter, IStaking, Util, PermissionControl, Pausable {
    using SafeMath for uint256;

    bool private _initialized = false;

    uint256 public periodIdCounter = 0;
    // PeriodId start from 1
    mapping(uint256 => Period) public periods;

    Staking public stakingLogic_;
    ILiquidityBootstrapAuction public lba_;
    EnergyStorage public energyStorage_;
    EnergyStorage public lbaEnergyStorage_;

    uint256 public constant ASTO_TOKEN_ID = 0;
    uint256 public constant LP_TOKEN_ID = 1;

    event EnergyUsed(address addr, uint256 amount);
    event LBAEnergyUsed(address addr, uint256 amount);
    event PeriodAdded(uint256 time, uint256 periodId, Period period);
    event PeriodUpdated(uint256 time, uint256 periodId, Period period);

    constructor(
        address controller,
        ILiquidityBootstrapAuction lba,
        Period[] memory _periods
    ) {
        if (!_isContract(controller)) revert ContractError(INVALID_CONTROLLER);
        if (!_isContract(lba)) revert ContractError(INVALID_LBA_CONTRACT);
        lba_ = ILiquidityBootstrapAuction(lba);
        _grantRole(CONTROLLER_ROLE, controller);
        _grantRole(USER_ROLE, controller);
        _addPeriods(_periods);
        _pause();
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

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
    function _calculateEnergyForToken(Stake[] memory history, uint256 multiplier) private view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = history.length; i > 0; i--) {
            if (currentTime() < history[i - 1].time) continue;

            uint256 elapsedTime = i == history.length
                ? currentTime().sub(history[i - 1].time)
                : history[i].time.sub(history[i - 1].time);

            total = total.add(elapsedTime.mul(history[i - 1].amount).mul(multiplier));
        }
        return total.div(SECONDS_PER_DAY);
    }

    function _calculateAvailableEnergyForLBA(address addr, uint256 periodId) private view returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);

        Period memory period = getPeriod(periodId);

        uint256 lbaEnergyStartTime = lba_.lpTokenReleaseTime();
        if (period.endTime < lbaEnergyStartTime) return 0;

        uint256 period = period.endTime - lbaEnergyStartTime;
        uint256 lbaLPAmount = _lba.claimableLPAmount(addr);

        return period.mul(lbaLPAmount).mul(period.lbaLPMultiplier).div(SECONDS_PER_DAY);
    }

    function getRemainingLBAEnergy(address addr, uint256 periodId) public view returns (uint256) {
        uint256 availableEnergy = _calculateAvailableEnergyForLBA(addr, periodId);
        if (availableEnergy > 0) return availableEnergy - getConsumedLBAEnergy(addr);
        return 0;
    }

    function getConsumedLBAEnergy(address addr) public view returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        return lbaEnergyStorage_.consumedAmount(addr);
    }

    /**
     * @dev Get the energy amount available for address `addr`
     *
     * @param addr The wallet address to get energy for
     * @param periodId The period id for energy calculation
     * @return Energy amount available
     */
    function getEnergy(address addr, uint256 periodId) public view returns (uint256) {
        return calculateEnergy(addr, periodId) - getConsumedEnergy(addr) + getRemainingLBAEnergy(addr, periodId);
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
    ) external whenNotPaused onlyRole(USER_ROLE) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);
        if (amount > getEnergy(addr, periodId)) revert InvalidInput(WRONG_AMOUNT);

        uint256 remainingLBAEnergy = getRemainingLBAEnergy(addr, periodId);
        uint256 lbaEnergyToSpend = Math.min(amount, remainingLBAEnergy);

        if (lbaEnergyToSpend > 0) {
            lbaEnergyStorage_.increaseConsumedAmount(addr, lbaEnergyToSpend);
            emit LBAEnergyUsed(addr, lbaEnergyToSpend);
        }

        uint256 energyToSpend = amount - lbaEnergyToSpend;
        if (energyToSpend > 0) {
            energyStorage_.increaseConsumedAmount(addr, amount);
            emit EnergyUsed(addr, energyToSpend);
        }
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

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
     * @notice Get the current period based on current timestamp
     *
     * @return current period data
     */
    function getCurrentPeriod() public view returns (Period memory) {
        return periods[getCurrentPeriodId()];
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
     * ! Administration          | MANAGER
     * ----------------------------------- */

    function setUser(address addr) external onlyRole(MANAGER_ROLE) {
        _updateRole(USER_ROLE, addr);
    }

    /**
     * @dev Add new periods
     * @dev This is a private function, can only be called in this contract
     *
     * @param _periods The list of periods to be added
     */
    function _addPeriods(Period[] memory _periods) private {
        for (uint256 i = 0; i < _periods.length; i++) {
            _addPeriod(_periods[i]);
        }
    }

    /**
     * @dev Add new periods
     * @dev Only manager contract has the permission to call this function
     *
     * @param _periods The list of periods to be added
     */
    function addPeriods(Period[] memory _periods) public onlyRole(MANAGER_ROLE) {
        _addPeriods(_periods);
    }

    /**
     * @dev Add a new period
     * @dev This is an internal function
     *
     * @param period The period instance to add
     */
    function _addPeriod(Period memory period) private {
        periods[++periodIdCounter] = period;
        emit PeriodAdded(currentTime(), periodIdCounter, period);
    }

    /**
     * @dev Add a new period
     * @dev Only manager contract has the permission to call this function
     *
     * @param period The period instance to add
     */
    function addPeriod(Period memory period) external onlyRole(MANAGER_ROLE) {
        _addPeriod(period);
    }

    /**
     * @dev Update a period
     * @dev This is an internal function
     *
     * @param periodId The period id to update
     * @param period The period data to update
     */
    function _updatePeriod(uint256 periodId, Period memory period) private {
        if (periodId == 0 || periodId > periodIdCounter) revert ContractError(WRONG_PERIOD_ID);
        periods[periodId] = period;
        emit PeriodUpdated(currentTime(), periodId, period);
    }

    /**
     * @dev Update a period
     * @dev Only manager contract has the permission to call this function
     *
     * @param periodId The period id to update
     * @param period The period data to update
     */
    function updatePeriod(uint256 periodId, Period memory period) external onlyRole(MANAGER_ROLE) {
        _updatePeriod(periodId, period);
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
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
        address lbaEnergyStorage,
        address stakingLogic
    ) external onlyRole(CONTROLLER_ROLE) {
        if (_initialized) revert ContractError(ALREADY_INITIALIZED);

        if (!_isContract(energyStorage)) revert ContractError(INVALID_ENERGY_STORAGE);
        if (!_isContract(lbaEnergyStorage)) revert ContractError(INVALID_LBA_ENERGY_STORAGE);
        if (!_isContract(stakingLogic)) revert ContractError(INVALID_STAKING_LOGIC);

        stakingLogic_ = Staking(stakingLogic);
        energyStorage_ = EnergyStorage(energyStorage);
        lbaEnergyStorage_ = EnergyStorage(lbaEnergyStorage);

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

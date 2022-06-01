// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Util.sol";
import "./helpers/IConverter.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Converter Storage contract
 */
contract ConverterStorage is TimeConstants, IConverter, Util, Pausable, Ownable, PermissionControl {
    address private _multisig;
    bool private initialized = false;

    uint256 public periodIdCounter = 0;
    // PeriodId start from 1
    mapping(uint256 => Period) public periods;

    // PeriodId to total balance mapping
    mapping(uint256 => uint256) public periodTotalBalance;
    // Balance of each period for the address
    mapping(address => mapping(uint256 => uint256)) public balances;

    /**
     * @param multisig Multisig address as the contract owner
     */
    constructor(address multisig) {
        if (address(multisig) == address(0)) revert ContractError(INVALID_MULTISIG);
        _multisig = multisig;
        _pause();
    }

    /**
     * @notice Update balance for `addr` on period `periodId`
     * @notice Function can be called only manager
     *
     * @param periodId - id of period to update
     * @param addr - user address
     * @param balance - new balance
     */
    function updateBalance(
        uint256 periodId,
        address addr,
        uint256 balance
    ) external whenNotPaused onlyRole(MANAGER_ROLE) {
        if (address(addr) == address(0)) revert ContractError(WRONG_ADDRESS);

        uint256 prevBalance = balances[addr][periodId];
        balances[addr][periodId] = balance;

        periodTotalBalance[periodId] = periodTotalBalance[periodId] - prevBalance + balance;
    }

    /**
     * @notice Get the total balance across all periods
     *
     * @return total balance
     */
    function totalBalance() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 index = 1; index <= periodIdCounter; index++) {
            total += periodTotalBalance[index];
        }
        return total;
    }

    /**
     * @notice Setup new period
     * @notice Function can be called only manager
     *
     */
    function setupPeriod(
        uint128 startTime,
        uint128 duration,
        address[] memory tokens,
        uint256[] memory multipliers
    ) external whenNotPaused onlyRole(MANAGER_ROLE) {
        if (tokens.length != multipliers.length) revert ContractError(WRONG_ARGUMENTS);

        Period storage p = periods[++periodIdCounter];
        p.startTime = startTime;
        p.duration = duration;
        for (uint256 i = 0; i < tokens.length; i++) {
            p.multipliers[tokens[i]] = multipliers[i];
        }
    }

    /**
     * @notice Get the current periodId based on current timestamp
     *
     * @return current periodId
     */
    function currentPeriodId() public view returns (uint256) {
        for (uint256 index = 1; index <= periodIdCounter; index++) {
            Period storage p = periods[index];
            if (currentTime() >= uint256(p.startTime) && currentTime() < uint256(p.startTime) + uint256(p.duration)) {
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
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @param registry Registry contract address
     * @param converterLogic Converter contract address
     */
    function init(address registry, address converterLogic) external onlyOwner {
        require(!initialized, "The contract has already been initialized.");
        if (!_isContract(registry)) revert ContractError(INVALID_REGISTRY);
        if (!_isContract(converterLogic)) revert ContractError(INVALID_CONVERTER_LOGIC);

        _setupRole(REGISTRY_ROLE, registry);
        _setupRole(MANAGER_ROLE, converterLogic);
        _unpause();
        _transferOwnership(_multisig);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

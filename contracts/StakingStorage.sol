// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./Registry.sol";
import "./Staking.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Storage contract
 */
contract StakingStorage is IStaking, PermissionControl, Util, Pausable {
    bool private initialized = false;

    uint256 private _totalCounter;
    // Incremented total stakes counter, pointing to the address of who staked
    mapping(uint256 => address) private _stakes; // _totalStakesCounter => user address
    // Incrementing stake Id used to record history
    mapping(address => uint256) private _stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint256 => Stake)) private _stakeHistory;

    /**
     * @dev 1. Contracts addresses for the roles are not known yet
     * @dev 2. Do setup before transfer ownership to the DAO's multisig contract
     */
    constructor() {
        address deployer = msg.sender;
        _setupRole(MANAGER_ROLE, deployer);
        _setupRole(REGISTRY_ROLE, deployer);
        _setupRole(STAKER_ROLE, deployer);
        _pause();
    }

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only Staker is allowed to save into this storage
     * @dev only Registry is allowed to update permissions - to reduce amount of DAO votings
     * @dev
     *
     * @param multisig Multisig address as the contract owner
     * @param registry Registry contract address
     * @param stakingLogic Staking contract address
     */
    function init(
        address multisig,
        address registry,
        address stakingLogic
    ) public onlyRole(MANAGER_ROLE) {
        require(initialized == false, ALREADY_INITIALIZED);

        if (!_isContract(multisig)) revert ContractError(INVALID_MULTISIG);
        if (!_isContract(registry)) revert ContractError(INVALID_REGISTRY);
        if (!_isContract(stakingLogic)) revert ContractError(INVALID_STAKING_LOGIC);

        _updateRole(MANAGER_ROLE, multisig);
        _updateRole(REGISTRY_ROLE, registry);
        _updateRole(STAKER_ROLE, stakingLogic);
        _grantRole(MANAGER_ROLE, registry);

        _unpause();
        initialized = true;
    }

    /**
     * @notice Saving stakes into storage.
     * @notice Function can be called only manager
     * @notice
     * @notice
     *
     * @dev
     *
     * @param tokenId - address of token to stake
     * @param addr - user address
     * @param amount - amount of tokens to stake
     * @return stakeID
     */
    function updateHistory(
        uint256 tokenId,
        address addr,
        uint256 amount
    ) public onlyRole(STAKER_ROLE) returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (amount <= 0) revert InvalidInput(WRONG_AMOUNT);

        _stakes[++_totalCounter] = addr; // incrementing total stakes counter

        uint128 time = uint128(block.timestamp); // not more that 1 stake per second
        Stake memory newStake = Stake(tokenId, time, amount);
        uint256 userStakeId = ++_stakeIds[addr]; // ++i cheaper than i++, so, stakeIds starts from 1
        _stakeHistory[addr][userStakeId] = newStake;
        return userStakeId;
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    function getTotalStakesCounter() public view returns (uint256) {
        return _totalCounter;
    }

    function getStake(address addr, uint256 id) public view returns (Stake memory) {
        return _stakeHistory[addr][id];
    }

    function getUserLastStakeId(address addr) public view returns (uint256) {
        return _stakeIds[addr];
    }

    function getLastStakeId() public view returns (uint256) {
        return _stakeIds[_stakes[_totalCounter]];
    }

    /** ----------------------------------
     * ! Controls
     * ----------------------------------- */

    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }
}

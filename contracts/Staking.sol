// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";

import "./Controller.sol";
import "./helpers/Util.sol";
import "./StakingStorage.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Logic contract
 */

contract Staking is IStaking, TimeConstants, Util, PermissionControl, Pausable {
    using SafeERC20 for IERC20;

    bool private initialized = false;

    /**
     * `_token`:  tokenId => token contract address
     * `_token`:  tokenId => token name
     * `_storage`:  tokenId => storage contract address
     * `_totalStakedAmount`:  tokenId => total staked amount for that tokenId
     *
     * IDs: 0 for ASTO, 1 for LP tokens
     */
    mapping(uint256 => IERC20) private _token;
    mapping(uint256 => string) private _tokenName;
    mapping(uint256 => StakingStorage) private _storage;
    mapping(uint256 => uint256) private _totalStakedAmount;

    constructor(address controller) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        _setupRole(CONTROLLER_ROLE, controller);
        _setupRole(MANAGER_ROLE, controller);
        _pause();
    }

    /** ----------------------------------
     * ! Admin functions
     * ----------------------------------- */

    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(CONTROLLER_ROLE, newController);
    }

    /**
     * @notice Withdraw tokens left in the contract to specified address
     * @param tokenId - ID of token to stake
     * @param recipient recipient of the transfer
     * @param amount Token amount to withdraw
     */
    function withdraw(
        uint256 tokenId,
        address recipient,
        uint256 amount
    )
        public
        whenPaused // when contract is paused ONLY
        onlyRole(MANAGER_ROLE)
    {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (address(recipient) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (_token[tokenId].balanceOf(address(this)) < amount) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransfer(recipient, amount);
    }

    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only Manager is allowed to call admin functions
     * @dev only controller is allowed to update permissions - to reduce amount of DAO votings
     *
     * @param astoToken ASTO Token contract address
     * @param lpToken LP Token contract address
     * @param astoStorage ASTO staking storage contract address
     * @param lpStorage LP staking storage contract address
     */
    function init(
        address manager,
        IERC20 astoToken,
        address astoStorage,
        IERC20 lpToken,
        address lpStorage
    ) public onlyRole(CONTROLLER_ROLE) {
        require(initialized == false, ALREADY_INITIALIZED);

        _token[0] = astoToken;
        _storage[0] = StakingStorage(astoStorage);

        _token[1] = lpToken;
        _storage[1] = StakingStorage(lpStorage);

        _updateRole(MANAGER_ROLE, manager);
        _unpause();
        initialized = true;
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @notice Staking is a process of locking your tokens in this contract.
     * @notice Details of the stake are to be stored and used for calculations
     * @notice what time your tokens are stay staked.
     * @notice You can always unlock your token. See `unstake()`.
     *
     * @dev Emit `Staked` event when successful, with address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function stake(uint256 tokenId, uint256 amount) external whenNotPaused {
        if (tokenId > 1) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);
        address user = msg.sender;
        uint256 userBalance = _token[tokenId].balanceOf(user);
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransferFrom(user, address(this), amount);
        _storage[tokenId].updateHistory(user, amount);
        _totalStakedAmount[tokenId] += amount;

        emit Staked(_tokenName[tokenId], user, block.timestamp, amount);
    }

    /**
     * @notice
     * @notice
     *
     * @dev Emit `UnStaked` event when successful, with address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function unstake(uint256 tokenId, uint256 amount) external {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);

        address user = msg.sender;
        uint256 id = _storage[tokenId].getUserLastStakeId(user);
        if (id == 0) revert InvalidInput(NO_STAKES);
        uint256 userBalance = (_storage[tokenId].getStake(user, id)).amount;
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        uint256 newAmount = userBalance - amount;
        _storage[tokenId].updateHistory(user, newAmount);
        _totalStakedAmount[tokenId] -= amount; // TODO: add tests for checking totalAmount

        _token[tokenId].safeTransfer(user, amount);

        emit UnStaked(_tokenName[tokenId], user, block.timestamp, amount);
    }

    /**
     * @notice Returns the total amount of tokens staked by all users
     * @param tokenId ASTO/LBA/LP
     * @return amount of tokens staked in the contract, uint256
     */
    function getTotalValueLocked(uint256 tokenId) external view returns (uint256) {
        return _totalStakedAmount[tokenId];
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    function getStorageAddress(uint256 tokenId) public view returns (address) {
        return address(_storage[tokenId]);
    }

    function getTokenAddress(uint256 tokenId) public view returns (address) {
        return address(_token[tokenId]);
    }

    function getHistory(
        uint256 tokenId,
        address addr,
        uint256 endTime
    ) public returns (Stake[] memory) {
        return _storage[tokenId].getHistory(addr, endTime);
    }
}

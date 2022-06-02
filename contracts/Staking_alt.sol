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

contract Staking_alt is IStaking, TimeConstants, Util, PermissionControl, Pausable {
    using SafeERC20 for IERC20;

    bool private initialized = false;

    IERC20 public asto_;
    IERC20 public lp_;
    StakingStorage public astoStorage_;
    StakingStorage public lpStorage_;
    uint256 totalAstoAmount;
    uint256 totalLpAmount;

    constructor(address controller) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        _setupRole(CONTROLLER_ROLE, controller);
        _setupRole(MANAGER_ROLE, controller);
        _pause();
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

        asto_ = astoToken;
        lp_ = lpToken;
        astoStorage_ = StakingStorage(astoStorage);
        lpStorage_ = StakingStorage(lpStorage);

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
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);
        address user = msg.sender;
        if (tokenId == 0) _stakeAsto(amount, user);
        else if (tokenId == 1) _stakeLp(amount, user);
        else revert InvalidInput(WRONG_TOKEN);
    }

    function _stakeAsto(uint256 amount, address user) internal whenNotPaused {
        uint256 userBalance = asto_.balanceOf(user);
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        asto_.safeTransferFrom(user, address(this), amount);
        astoStorage_.updateHistory(user, amount);
        totalAstoAmount += amount;

        emit Staked("ASTO", user, block.timestamp, amount);
    }

    function _stakeLp(uint256 amount, address user) internal whenNotPaused {
        uint256 userBalance = lp_.balanceOf(user);
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        lp_.safeTransferFrom(user, address(this), amount);
        lpStorage_.updateHistory(user, amount);
        totalLpAmount += amount;

        emit Staked("ASTO", user, block.timestamp, amount);
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
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);
        address user = msg.sender;

        if (tokenId == 0) _stakeAsto(amount, user);
        else if (tokenId == 1) _stakeLp(amount, user);
        else revert InvalidInput(WRONG_TOKEN);
    }

    function _unstakeAsto(uint256 amount, address user) internal {
        uint256 id = astoStorage_.getUserLastStakeId(user);
        if (id == 0) revert InvalidInput(NO_STAKES);
        uint256 userBalance = (astoStorage_.getStake(user, id)).amount;
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        uint256 newAmount = userBalance - amount;
        astoStorage_.updateHistory(user, newAmount);
        totalAstoAmount += amount;

        asto_.safeTransfer(user, amount);

        emit UnStaked("ASTO", user, block.timestamp, amount);
    }

    function _unstakeLp(uint256 amount, address user) internal {
        uint256 id = lpStorage_.getUserLastStakeId(user);
        if (id == 0) revert InvalidInput(NO_STAKES);
        uint256 userBalance = (lpStorage_.getStake(user, id)).amount;
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        uint256 newAmount = userBalance - amount;
        lpStorage_.updateHistory(user, newAmount);
        totalLpAmount += amount;

        lp_.safeTransfer(user, amount);

        emit UnStaked("LP", user, block.timestamp, amount);
    }

    /**
     * @notice Returns the total amount of tokens staked by all users
     * @return amount of tokens staked in the contract, uint256
     */
    function getTotalAstoLocked() external view returns (uint256) {
        return totalAstoAmount;
    }

    function getTotalLpLocked() external view returns (uint256) {
        return totalLpAmount;
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    function getAstoStorageAddress() public view returns (address) {
        return address(lpStorage_);
    }

    function getLpStorageAddress() public view returns (address) {
        return address(lpStorage_);
    }

    function getAstoTokenAddress() public view returns (address) {
        return address(asto_);
    }

    function getLpTokenAddress() public view returns (address) {
        return address(lp_);
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
        if (address(recipient) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (tokenId == 0) _withdrawAsto(recipient, amount);
        else if (tokenId == 1) _withdrawLp(recipient, amount);
        else revert InvalidInput(WRONG_TOKEN);
    }

    function _withdrawAsto(address recipient, uint256 amount) internal {
        if (asto_.balanceOf(address(this)) < amount) revert InvalidInput(INSUFFICIENT_BALANCE);
        asto_.safeTransfer(recipient, amount);
    }

    function _withdrawLp(address recipient, uint256 amount) internal {
        if (lp_.balanceOf(address(this)) < amount) revert InvalidInput(INSUFFICIENT_BALANCE);
        asto_.safeTransfer(recipient, amount);
    }

    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }
}

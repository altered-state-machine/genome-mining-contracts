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

    StakingStorage private storage_;
    IERC20 public asto_;
    IERC20 public lp_;
    uint256 private _totalTokens;
    bool private initialized = false;

    mapping(uint256 => IERC20) public tokens; // asto - 1, lp - 2

    // Stores total amount for the token: token => amount
    mapping(uint256 => uint256) private _totalStakedAmount;

    /**
     * @dev 1. Contracts addresses for the roles are not known yet
     * @dev 2. Do setup before transfer ownership to the DAO's multisig contract
     */
    constructor() {
        address deployer = msg.sender;
        _setupRole(CONTROLLER_ROLE, deployer);
        _pause();
    }

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only Manager is allowed to call admin functions
     * @dev only controller is allowed to update permissions - to reduce amount of DAO votings
     *
     * @param controller controller contract address
     * @param stakingStorage Staking contract address
     * @param astoContract ASTO Token contract address
     * @param lpContract LP Token contract address
     */
    function init(
        address controller,
        address stakingStorage,
        IERC20 astoContract,
        IERC20 lpContract
    ) public onlyRole(CONTROLLER_ROLE) {
        require(initialized == false, ALREADY_INITIALIZED);

        storage_ = StakingStorage(stakingStorage);
        asto_ = astoContract;
        lp_ = lpContract;

        _updateRole(CONTROLLER_ROLE, controller);
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
        if (!_isContract(address(tokens[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (amount <= 0) revert InvalidInput(WRONG_AMOUNT);
        address user = msg.sender;
        uint256 userBalance = tokens[tokenId].balanceOf(user);
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        tokens[tokenId].safeTransferFrom(user, address(this), amount);

        storage_.updateHistory(user, amount);
        _totalStakedAmount[tokenId] += amount;

        emit Staked(user, block.timestamp, amount);
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
        if (!_isContract(address(tokens[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (amount <= 0) revert InvalidInput(WRONG_AMOUNT);

        address user = msg.sender;
        uint256 id = storage_.getUserLastStakeId(user);
        if (id == 0) revert InvalidInput(NO_STAKES);
        uint256 userBalance = (storage_.getStake(user, id)).amount;
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        uint256 newAmount = userBalance - amount;
        storage_.updateHistory(user, newAmount);
        _totalStakedAmount[tokenId] += amount;

        tokens[tokenId].safeTransfer(user, amount);

        emit UnStaked(user, block.timestamp, amount);
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

    function getStorageAddress() public view returns (address) {
        return address(storage_);
    }

    /** ----------------------------------
     * ! Admin functions
     * ----------------------------------- */

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
        if (!_isContract(address(tokens[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (address(recipient) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (tokens[tokenId].balanceOf(address(this)) < amount) revert InvalidInput(INSUFFICIENT_BALANCE);

        tokens[tokenId].safeTransfer(recipient, amount);
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }
}

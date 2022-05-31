// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Tokens.sol";
import "./Registry.sol";
import "./helpers/Util.sol";
import "./StakingStorage.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Logic contract
 */

contract Staking is IStaking, Tokens, TimeConstants, Util, PermissionControl, Pausable, Ownable {
    using SafeERC20 for IERC20;

    bool private initialized = false;
    address private _multisig;
    StakingStorage private storage_;

    /**
     * @param multisig Multisig address as the contract owner
     */
    constructor(address multisig) {
        if (address(multisig) == address(0)) {
            revert WrongAddress(multisig, INVALID_MULTISIG);
        }
        _multisig = multisig;
        _pause();
    }

    /**
     * @param registry Registry contract address
     * @param stakingStorage Staking Storage contract address
     */
    function init(address registry, address stakingStorage) external onlyOwner {
        require(initialized == false, ALREADY_INITIALIZED);
        if (!_isContract(registry)) {
            revert WrongAddress(registry, INVALID_REGISTRY);
        }
        if (!_isContract(stakingStorage)) {
            revert WrongAddress(stakingStorage, INVALID_STAKING_STORAGE);
        }

        storage_ = StakingStorage(stakingStorage);
        _setupRole(REGISTRY_ROLE, registry);
        _unpause();
        _transferOwnership(_multisig);

        initialized = true;
    }

    /** ----------------------------------
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @notice Withdraw tokens left in the contract to specified address
     * @param recipient recipient of the transfer
     * @param amount Token amount to withdraw
     */
    function withdraw(
        Token token,
        address recipient,
        uint256 amount
    )
        external
        onlyOwner
        whenPaused // ? TODO: to discuss: withdraw allowed when the contract paused only?
    {
        if (!_isCorrectToken(token)) revert WrongToken(uint8(token));
        if (address(recipient) == address(0)) revert WrongParameter(WRONG_ADDRESS);

        if (contractOf[token].balanceOf(address(this)) <= 0) revert WrongParameter(INSUFFICIENT_BALANCE);

        contractOf[token].safeTransfer(recipient, amount);
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
     * @param token - Which Token to stake
     * @param amount - amount of tokens to stake
     */
    function stake(Token token, uint256 amount) public whenNotPaused {
        if (!_isCorrectToken(token)) revert WrongToken(uint8(token));
        if (amount <= 0) revert WrongParameter(WRONG_AMOUNT);
        address user = msg.sender;
        uint256 userBalance = ASTO_TOKEN.balanceOf(user);
        if (amount > userBalance) revert InsufficientBalance(token, INSUFFICIENT_BALANCE);

        // _beforeTokenTransfer(...);

        contractOf[token].approve(address(this), amount);
        contractOf[token].safeTransferFrom(user, address(this), amount);
        storage_.updateHistory(token, user, amount);
        emit Staked(user, block.timestamp, amount);
    }

    /**
     * @notice
     * @notice
     *
     * @dev Emit `UnStaked` event when successful, with address, timestamp, amount
     *
     * @param token - Which Token to stake
     * @param amount - amount of tokens to stake
     */
    function unStake(Token token, uint256 amount) public {
        if (!_isCorrectToken(token)) revert WrongToken(uint8(token));
        if (amount <= 0) revert WrongParameter(WRONG_AMOUNT);

        address user = msg.sender;
        uint256 id = storage_.getUserLastStakeId(user);
        if (id == 0) revert NoStakes(user);
        uint256 userBalance = (storage_.getStake(user, id)).amount;
        uint256 newAmount = userBalance - amount;

        if (amount > userBalance) revert InsufficientBalance(token, INSUFFICIENT_BALANCE);

        storage_.updateHistory(token, user, newAmount);

        // _beforeTokenTransfer(...);
        contractOf[token].safeTransfer(user, amount);
        emit UnStaked(user, block.timestamp, amount);
    }

    /**
     * @notice Returns the total amount of tokens staked by all users
     * @param token ASTO/LBA/LP
     * @return amount of tokens staked in the contract, uint256
     */
    function getTotalValueLocked(Token token) external onlyOwner returns (uint256) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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
    bool private initialized = false;
    address private _multisig;

    // Inrementing stake Id used to record history
    mapping(address => uint16) public stakeIds;
    // Incremented total stakes counter, pointing to the address of who staked
    mapping(uint16 => address) public allStakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint16 => Stake)) public stakeHistory;

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
        require(tokens[token].balanceOf(address(this)) > 1, INPUT_INSUFFIENT_BALANCE);
        tokens[token].approve(recipient, amount);
        tokens[token].transferFrom(address(this), recipient, amount);
    }

    /** ----------------------------------
     * ! User functions
     * ----------------------------------- */

    /**
     * @notice Staking is a process of locking your tokens in this contract.
     * @notice Details of the stake are to be stored and used for calculations
     * @notice what time your tokens are stay staked.
     * @notice You can always unlock your token. See `unstake()`.
     *
     * @dev Emit `Stake` event when successful, with timestamp, address, amount
     *
     * @param _amount - amount of tokens to stake
     */
    function stake(Token token, uint256 _amount) public {
        uint16 currentStakeId = stakeIds[msg.sender];
        uint16 nextStakeId = currentStakeId + 1;

        uint256 currentStakeBalance = stakeHistory[msg.sender][currentStakeId].amount;
        uint256 nextStakeBalance = currentStakeBalance + _amount;

        stakeIds[msg.sender] = nextStakeId;
        stakeHistory[msg.sender][nextStakeId] = Stake({
            token: token,
            amount: nextStakeBalance,
            time: uint128(block.timestamp)
        });
        // _beforeTokenTransfer(...);
        // transfer tokens from sender to contract
        // emit Stake(walletAddress, timestamp, amount);
    }

    /**
     * @notice
     * @notice
     *
     * @dev Emit `Unstake` event when successful, with timestamp, address, amount
     *
     * @param _amount - list of existing stake IDs belonging to the caller (msg.Sender)
     */
    function unstake(Token token, uint256 _amount) public {
        uint16 currentStakeId = stakeIds[msg.sender];
        uint16 nextStakeId = currentStakeId + 1;

        uint256 currentStakeBalance = stakeHistory[msg.sender][currentStakeId].amount;

        require(currentStakeBalance >= _amount, INPUT_INSUFFIENT_STAKED_AMOUNT);
        uint256 nextStakeBalance = currentStakeBalance - _amount;

        stakeIds[msg.sender] = nextStakeId;
        stakeHistory[msg.sender][nextStakeId] = Stake({
            token: token,
            amount: nextStakeBalance,
            time: uint128(block.timestamp)
        });
        // _beforeTokenTransfer(...);
        // transfer tokens from contract to sender
        // emit Unstake(walletAddress, timestamp, amount);
    }

    /**
     * @notice Returns the total amount of tokens staked by all users
     *
     * @return amount of tokens staked in the contract, uint256
     */
    function getTotalValueLocked() external onlyOwner returns (uint256) {}
}

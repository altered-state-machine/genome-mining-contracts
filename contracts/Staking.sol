// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ITime.sol";
import "./TimeConstants.sol";

/**
 * @dev ASM Genome Mining - ASTO Time contract
 */
contract Staking is ITime, TimeConstants, Pausable, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable tokenAddress;
    // Inrementing stake Id used to record history
    mapping(address => uint16) public stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint16 => Stake)) public stakeHistory;

    /**
     * @notice Initialize the contract
     * @param multisig Multisig address as the contract owner
     * @param _tokenAddress $ASTO contract address
     */
    constructor(address multisig, IERC20 _tokenAddress) {
        require(address(multisig) != address(0), "invalid multisig address");
        require(
            address(_tokenAddress) != address(0),
            "invalid contract address"
        );

        // mainnet: 0x823556202e86763853b40e9cDE725f412e294689
        // rinkeby: ...
        tokenAddress = _tokenAddress;
        _pause();
        _transferOwnership(multisig);
    }

    /** ----------------------------------
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @notice Withdraw tokens left in the contract to specified address
     * @param recipient recipient of the transfer
     * @param amount Token amount to withdraw
     */
    function withdraw(address recipient, uint256 amount)
        external
        onlyOwner
        whenPaused // ? TODO: to discuss: withdraw allowed when the contract paused only?
    {
        require(
            tokenAddress.balanceOf(address(this)) > 1,
            "Insufficient token balance"
        );
        tokenAddress.approve(recipient, amount);
        tokenAddress.transferFrom(address(this), recipient, amount);
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
    function stake(uint256 _amount) public {
        uint16 currentStakeId = stakeIds[msg.sender];
        uint16 nextStakeId = currentStakeId + 1;

        uint256 currentStakeBalance = stakeHistory[msg.sender][currentStakeId]
            .amount;
        uint256 nextStakeBalance = currentStakeBalance + _amount;

        stakeIds[msg.sender] = nextStakeId;
        stakeHistory[msg.sender][nextStakeId] = Stake({
            amount: nextStakeBalance,
            time: block.timestamp
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

    function unstake(uint256 _amount) public {
        uint16 currentStakeId = stakeIds[msg.sender];
        uint16 nextStakeId = currentStakeId + 1;

        uint256 currentStakeBalance = stakeHistory[msg.sender][currentStakeId]
            .amount;

        require(currentStakeBalance >= _amount, "Amount larger than staked");
        uint256 nextStakeBalance = currentStakeBalance - _amount;

        stakeIds[msg.sender] = nextStakeId;
        stakeHistory[msg.sender][nextStakeId] = Stake({
            amount: nextStakeBalance,
            time: block.timestamp
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

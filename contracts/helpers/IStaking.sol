// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ITokens.sol";

/**
 * @dev For testing purpose
 */
interface IStaking is ITokens {
    event Staked(address indexed staker, uint256 timestamp, uint256 amount);
    event UnStaked(address indexed staker, uint256 timestamp, uint256 amount);

    struct Stake {
        uint256 tokenId; // uint8 is used for enums, so the whole struct takes 2 uint256 slots
        uint128 time; // Time for precise calculations
        uint256 amount; // New amount on every new (un)stake
    }
}

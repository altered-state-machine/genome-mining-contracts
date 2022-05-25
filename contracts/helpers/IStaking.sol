// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev For testing purpose
 */
interface IStaking {
    struct Stake {
        uint256 time; // Time for precision calculations
        uint256 amount; // New amount on every new (un)stake
    }
}

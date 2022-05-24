// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface of the ASM Genome Mining contract.
 */
interface ITime {
    struct Stake {
        uint256 time; // Time for precision calculations
        uint256 amount; // New amount on every new (un)stake
    }
}

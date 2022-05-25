// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev ASM Genome Mining - Tokens
 * list of tokens we use
 */
contract Tokens {
    IERC20 immutable asto = IERC20(0x823556202e86763853b40e9cDE725f412e294689);
    IERC20 immutable lba = IERC20(0x823556202e86763853b40e9cDE725f412e294689);
    IERC20 immutable lp = IERC20(0x823556202e86763853b40e9cDE725f412e294689);
}

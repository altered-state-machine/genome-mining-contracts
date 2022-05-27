// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokens.sol";

/**
 * @dev ASM Genome Mining - Tokens
 * list of tokens we use
 */
contract Tokens is ITokens {
    IERC20 immutable ASTO_TOKEN =
        IERC20(0x823556202e86763853b40e9cDE725f412e294689);
    IERC20 immutable LBA_TOKEN =
        IERC20(0x823556202e86763853b40e9cDE725f412e294689);
    IERC20 immutable LP_TOKEN =
        IERC20(0x823556202e86763853b40e9cDE725f412e294689);

    mapping(Token => IERC20) tokens;

    constructor() {
        tokens[Token.ASTO] = ASTO_TOKEN;
        tokens[Token.LBA] = LBA_TOKEN;
        tokens[Token.LP] = LP_TOKEN;
    }
}

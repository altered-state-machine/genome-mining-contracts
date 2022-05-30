// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokens.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev ASM Genome Mining - Tokens
 * list of tokens we use
 */
contract Tokens is ITokens {
    using SafeERC20 for IERC20;

    IERC20 constant ASTO_TOKEN =
        IERC20(0x823556202e86763853b40e9cDE725f412e294689);
    IERC20 constant LBA_TOKEN =
        IERC20(0x823556202e86763853b40e9cDE725f412e294689);
    IERC20 constant LP_TOKEN =
        IERC20(0x823556202e86763853b40e9cDE725f412e294689);

    mapping(Token => IERC20) contractOf;

    constructor() {
        contractOf[Token.ASTO] = ASTO_TOKEN;
        contractOf[Token.LBA] = LBA_TOKEN;
        contractOf[Token.LP] = LP_TOKEN;
    }

    function _isCorrectToken(Token token) internal pure returns (bool) {
        return uint8(token) <= uint8(type(Token).max);
    }
}

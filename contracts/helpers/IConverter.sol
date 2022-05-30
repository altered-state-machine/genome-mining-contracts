// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev Interface for Converter
 */
interface IConverter {
    struct Period {
        uint128 startTime;
        uint128 duration;
        mapping(address => uint256) multipliers; // token address to multipliers
    }
}

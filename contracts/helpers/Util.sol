// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Tokens.sol";

/**
 * @dev ASM Genome Mining - Utility contract
 */
contract Util is Tokens {
    error WrongAddress(address addr, string errMsg);
    error WrongParameter(string errMsg);
    error WrongToken(uint8 uintRepresentation);
    error InsufficientBalance(Token token, string str);
    error NoStakes(address addr);

    string constant INVALID_MULTISIG = "Invalid Multisig address";
    string constant INVALID_REGISTRY = "Invalid Registry address";
    string constant INVALID_STAKING_LOGIC = "Invalid Staking Logic address";
    string constant INVALID_STAKING_STORAGE = "Invalid Staking Storage address";
    string constant INVALID_CONVERTER_LOGIC = "Invalid Converter Logic address";
    string constant INVALID_CONVERTER_STORAGE = "Invalid Converter Storage address";
    string constant ALREADY_INITIALIZED = "The contract has already been initialized";
    string constant WRONG_ADDRESS = "Wrong or missed wallet address";
    string constant WRONG_AMOUNT = "Wrong or missed amount";
    string constant INSUFFICIENT_BALANCE = "Insufficient token balance";
    string constant INSUFFICIENT_STAKED_AMOUNT = "Requested amount is greater than a stake";

    /**
     * @notice Among others, `isContract` will return false for the following
     * @notice types of addresses:
     * @notice  - an externally-owned account
     * @notice  - a contract in construction
     * @notice  - an address where a contract will be created
     * @notice  - an address where a contract lived, but was destroyed
     *
     * @dev Attention!
     * @dev if _isContract() called from the constructor,
     * @dev addr.code.length will be equal to 0, and
     * @dev this function will return false.
     *
     */
    function _isContract(address addr) internal view returns (bool) {
        return addr.code.length > 0;
    }
}

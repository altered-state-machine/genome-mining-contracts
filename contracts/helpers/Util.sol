// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Tokens.sol";

/**
 * @dev ASM Genome Mining - Utility contract
 */
contract Util {
    error InvalidInput(string errMsg);
    error ContractError(string errMsg);

    string constant ALREADY_INITIALIZED = "The contract has already been initialized";
    string constant INVALID_MULTISIG = "Invalid Multisig address";
    string constant INVALID_TOKENS = "Invalid Tokens contract address";
    string constant INVALID_REGISTRY = "Invalid Registry address";
    string constant INVALID_STAKING_LOGIC = "Invalid Staking Logic address";
    string constant INVALID_STAKING_STORAGE = "Invalid Staking Storage address";
    string constant INVALID_CONVERTER_LOGIC = "Invalid Converter Logic address";
    string constant INVALID_CONVERTER_STORAGE = "Invalid Converter Storage address";
    string constant WRONG_ADDRESS = "Wrong or missed wallet address";
    string constant WRONG_AMOUNT = "Wrong or missed amount";
    string constant WRONG_TOKEN = "Token not allowed for staking";
    string constant INSUFFICIENT_BALANCE = "Insufficient token balance";
    string constant INSUFFICIENT_STAKED_AMOUNT = "Requested amount is greater than a stake";
    string constant NO_STAKES = "No stakes yet";

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

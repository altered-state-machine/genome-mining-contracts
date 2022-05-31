// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev ASM Genome Mining - Utility contract
 */
contract Util {
    error WrongAddress(address addr, string errMsg);
    error WrongParameter(string errMsg);

    string constant INVALID_MULTISIG = "Invalid Multisig address";
    string constant INVALID_REGISTRY = "Invalid Registry address";
    string constant INVALID_STAKING_LOGIC = "Invalid Staking Logic address";
    string constant INVALID_STAKING_STORAGE = "Invalid Staking Storage address";
    string constant INVALID_CONVERTER_LOGIC = "Invalid Converter Logic address";
    string constant INVALID_CONVERTER_STORAGE = "Invalid Converter Storage address";

    string constant ALREADY_INITIALIZED = "The contract has already been initialized";
    string constant INVALID_ = "Invalid address";

    string constant INPUT_INSUFFIENT_BALANCE = "Insufficient token balance";
    string constant INPUT_INSUFFIENT_STAKED_AMOUNT = "Requested amount is greater than a stake";

    /**
     * @dev Attention!
     * @dev if _isContract() called from the constructor,
     * @dev addr.code.length will be equal to 0, and
     * @dev this function will return false.
     */
    function _isContract(address addr) internal view returns (bool) {
        return addr.code.length > 0;
    }
}

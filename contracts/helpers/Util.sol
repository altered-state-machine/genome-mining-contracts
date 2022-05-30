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

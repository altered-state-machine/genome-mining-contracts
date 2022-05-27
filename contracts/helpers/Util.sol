// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev ASM Genome Mining - Utility contract
 */
contract Util {
    error WrongAddress(address addr, string errMsg);
    error WrongParameter(string errMsg);

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

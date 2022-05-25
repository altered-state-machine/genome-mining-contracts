// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev ASM Genome Mining - Utility contract
 */
contract Util {
    error WrongAddress(address addr, string errMsg);

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

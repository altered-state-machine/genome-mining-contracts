// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Util.sol";

/**
 * @dev ASM Genome Mining - Manager contract
 */
contract Manager is Util, Pausable, Ownable {
    error WrongManager(address addr, string errMsg);

    address private _manager;

    function getManager() public view returns (address) {
        return _manager;
    }

    /**
     * @param newManager Managing contract address
     */
    function setManager(address newManager) external onlyOwner whenPaused {
        if (!_isContract(newManager)) {
            revert WrongAddress(newManager, "Invalid Manager address");
        }
        _manager = newManager;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        address msgSender = msg.sender;
        if (getManager() != msgSender) {
            revert WrongManager(msgSender, "Caller is not the Manager");
        }
        _;
    }
}

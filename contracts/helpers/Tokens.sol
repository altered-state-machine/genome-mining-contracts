// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Tokens
 * list of tokens we use
 */
contract Tokens is PermissionControl {
    using SafeERC20 for IERC20;

    // 0x823556202e86763853b40e9cDE725f412e294689

    mapping(uint256 => IERC20) public tokens;
    uint256 public totalTokens; // starts with 1

    constructor(IERC20 asto, IERC20 lp) {
        _addToken(asto);
        _addToken(lp);

        address deployer = msg.sender;
        _setupRole(REGISTRY_ROLE, deployer);
        _setupRole(MANAGER_ROLE, deployer);
    }

    function init(address multisig, address registry) external onlyRole(MANAGER_ROLE) {
        _updateRole(MANAGER_ROLE, multisig);
        _updateRole(REGISTRY_ROLE, registry);
    }

    function _addToken(IERC20 token) internal {
        tokens[++totalTokens] = token;
    }

    function addToken(IERC20 token) public onlyRole(MANAGER_ROLE) {
        _addToken(token);
    }

    function getTotalTokens() public view returns (uint256) {
        return totalTokens;
    }
}

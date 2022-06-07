// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPTokenTest is ERC20 {
    /**
     * @notice Initialize the contract
     */
    constructor() ERC20("Test LP", "LP") {}

    /**
     * @notice Mint `amount` LP tokens
     * @param amount The amount of tokens to be minted
     */
    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

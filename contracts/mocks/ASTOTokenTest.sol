// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ASTOTokenTest is ERC20 {
    /**
     * @notice Initialize the contract
     */
    constructor() ERC20("Test ASTO", "TESTASTO") {}

    /**
     * @notice Mint and deposit `amount` $ASTO tokens to AragonDAO Finance
     * @param amount The amount of tokens to be minted
     */
    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

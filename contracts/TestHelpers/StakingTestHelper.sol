// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../Staking.sol";

/**
 * @dev ASM ASTO Time test helper + SETTERS for testing
 */
contract StakingTestHelper is Staking {
    uint256 public currentTimestamp;

    /** ----------------------------------
     * ! Variables setters
     * ----------------------------------- */
    constructor(address multisig) Staking(multisig) {}

    function pause() public onlyOwner {
        _unpause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

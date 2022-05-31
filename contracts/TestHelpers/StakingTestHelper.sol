// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../Staking.sol";

/**
 * @dev ASM ASTO Time test helper + SETTERS for testing
 */
contract StakingTestHelper is Staking {
    uint256 public currentTimestamp;

    /** ----------------------------------
     * ! Variables setters
     * ----------------------------------- */
    constructor() Staking() {}
}

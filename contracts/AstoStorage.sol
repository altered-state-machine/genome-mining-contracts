// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./StakingStorage.sol";

/**
 * @dev ASM Genome Mining - Staking Storage contract
 */
contract AstoStorage is StakingStorage {
    constructor(address controller) StakingStorage(controller) {}
}

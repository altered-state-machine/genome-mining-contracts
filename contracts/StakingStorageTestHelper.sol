// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./StakingStorage.sol";

/**
 * @dev ASM LP Time test helper + SETTERS for testing
 */
contract StakingStorageTestHelper is StakingStorage {
    uint256 public currentTimestamp;

    /** ----------------------------------
     * ! Variables setters
     * ----------------------------------- */
    constructor(address multisig, IERC20 _astoTokenAddress)
        StakingStorage(multisig, _astoTokenAddress)
    {}

    function pause() public onlyOwner {
        _unpause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

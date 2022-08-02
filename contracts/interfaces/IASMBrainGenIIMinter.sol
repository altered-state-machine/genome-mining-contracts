// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev Interface for ASMBrainGenIIMinter
 */
interface IASMBrainGenIIMinter {
    error NotStarted();
    error AlreadyFinished();
    error InvalidSignature();
    error InvalidHashes(uint256 length, uint256 max, uint256 min);
    error InsufficientSupply(uint256 quantity, uint256 remaining);
    error InsufficientEnergy(uint256 amount, uint256 remaining);
    error InvalidPeriod(uint256 periodId, uint256 currentPeriodId);
}

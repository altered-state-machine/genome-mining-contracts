// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev ASM Genome Mining - ASTO Time constants we use
 */
contract TimeConstants {
    // all variables are public to make them available in tests
    uint256 public constant DAYS_PER_WEEK = 7;
    uint256 public constant HOURS_PER_DAY = 24;
    uint256 public constant MINUTES_PER_HOUR = 60;
    uint256 public constant SECONDS_PER_MINUTE = 60;
    uint256 public constant SECONDS_PER_HOUR = 3600;
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant SECONDS_PER_WEEK = 604800;
    uint256 public constant DURATION_WEEKS = 40;
    uint256 public constant DURATION_SECONDS =
        DURATION_WEEKS * SECONDS_PER_WEEK;
}

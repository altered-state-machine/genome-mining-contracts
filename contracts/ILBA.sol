// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILBA {
    function lpClaimed(address) external returns (uint256); // to emulate contract's mapping (the public one but without getter function)

    struct Timeline {
        uint256 auctionStartTime;
        uint256 astoDepositEndTime;
        uint256 usdcDepositEndTime;
        uint256 auctionEndTime;
    }

    struct Stats {
        uint256 totalDepositedASTO;
        uint256 totalDepositedUSDC;
        uint256 depositedASTO;
        uint256 depositedUSDC;
    }

    function deposit(uint256, uint256) external;

    function depositASTO(uint256) external;

    function depositUSDC(uint256) external;

    function withdrawableUSDCAmount(address) external view returns (uint256);

    function withdrawUSDC(uint256) external;

    function optimalDeposit(
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure returns (uint256);

    function addLiquidityToExchange(address, address) external;

    function claimLPToken() external;

    function claimableLPAmount(address) external view returns (uint256);

    function claimRewards(uint256) external;

    function claimableRewards(address) external view returns (uint16, uint256);

    function calculateRewards(address) external view returns (uint256);

    function calculateASTORewards(address) external view returns (uint256);

    function calculateUSDCRewards(address) external view returns (uint256);

    function withdrawToken(address, uint256) external;

    function astoDepositAllowed() external view returns (bool);

    function usdcDepositAllowed() external view returns (bool);

    function usdcWithdrawAllowed() external view returns (bool);

    function astoDepositEndTime() external view returns (uint256);

    function usdcDepositEndTime() external view returns (uint256);

    function usdcWithdrawLastDay() external view returns (uint256);

    function auctionEndTime() external view returns (uint256);

    function lpTokenReleaseTime() external view returns (uint256);

    function astoRewardAmount() external view returns (uint256);

    function usdcRewardAmount() external view returns (uint256);

    function setStartTime(uint256) external;

    function timeline() external view returns (Timeline memory);

    function stats(address) external view returns (Stats memory);

    function currentTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../ILBA.sol";

contract MockedLBA is ILBA, ERC20 {
    uint256 public lpTokenAmount;
    mapping(address => uint256) public lpClaimed;
    uint256 private _claimableAmount = 1e12;

    constructor(string memory name, string memory symbol) payable ERC20(name, symbol) {}

    /** ----------------------------------
     * ! Helpers
     * ----------------------------------- */

    function mint_helper(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function setLPClaimableAmount_helper(uint256 amount) public {}

    function setLPClaimed_helper(address account, uint256 amount) public {
        lpClaimed[account] = amount;
        _claimableAmount = amount;
    }

    /** ----------------------------------
     * ! Original functions
     * ----------------------------------- */

    function claimableLPAmount(address) public view returns (uint256) {
        return _claimableAmount;
    }

    function deposit(uint256, uint256) external {}

    function depositASTO(uint256) external {}

    function depositUSDC(uint256) external {}

    function withdrawableUSDCAmount(address) external view returns (uint256) {}

    function withdrawUSDC(uint256) external {}

    function optimalDeposit(
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure returns (uint256) {}

    function addLiquidityToExchange(address, address) external {}

    function claimLPToken() external {}

    function claimRewards(uint256) external {}

    function claimableRewards(address) external view returns (uint16, uint256) {}

    function calculateRewards(address) external view returns (uint256) {}

    function calculateASTORewards(address) external view returns (uint256) {}

    function calculateUSDCRewards(address) external view returns (uint256) {}

    function withdrawToken(address, uint256) external {}

    function astoDepositAllowed() external view returns (bool) {}

    function usdcDepositAllowed() external view returns (bool) {}

    function usdcWithdrawAllowed() external view returns (bool) {}

    function astoDepositEndTime() external view returns (uint256) {}

    function usdcDepositEndTime() external view returns (uint256) {}

    function usdcWithdrawLastDay() external view returns (uint256) {}

    function auctionEndTime() external view returns (uint256) {}

    function lpTokenReleaseTime() external view returns (uint256) {}

    function astoRewardAmount() external view returns (uint256) {}

    function usdcRewardAmount() external view returns (uint256) {}

    function setStartTime(uint256) external {}

    function timeline() external view returns (Timeline memory) {}

    function stats(address) external view returns (Stats memory) {}

    function currentTime() external view returns (uint256) {}
}

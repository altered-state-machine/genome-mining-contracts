// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ITime.sol";
import "./TimeConstants.sol";

/**
 * @dev ASM Genome Mining - LP Time contract
 */
contract StakingStorage is ITime, TimeConstants, Pausable, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable tokenAddress;

    /**
     * @notice Initialize the contract
     * @param multisig Multisig address as the contract owner
     * @param _tokenAddress $ASTO contract address
     */
    constructor(address multisig, IERC20 _tokenAddress) {
        require(address(multisig) != address(0), "invalid multisig address");
        require(
            address(_tokenAddress) != address(0),
            "invalid contract address"
        );

        // mainnet: 0x823556202e86763853b40e9cDE725f412e294689
        // rinkeby: ...
        tokenAddress = _tokenAddress;
        _pause();
        _transferOwnership(multisig);
    }

    /** ----------------------------------
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @notice
     * @param _address
     */
    function func(address _address) external onlyOwner {}
}

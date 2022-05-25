// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Tokens.sol";
import "./Registry.sol";
import "./helpers/Util.sol";

/**
 * @dev ASM Genome Mining - Staking Storage contract
 */
contract StakingStorage is Storage {
    using SafeERC20 for IERC20;
    bool private initialized = false;

    Staking public manager;

    // Inrementing stake Id used to record history
    mapping(address => uint16) public stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint16 => Stake)) public stakeHistory;

    /**
     * @param _multisig Multisig address as the contract owner
     * @param _storage Storage contract address
     */
    constructor(address _multisig, IERC20 _storage) {
        if (address(_multisig) == address(0)) {
            revert WrongAddress(_multisig, "Invalid Multisig address");
        }
        if (address(_storage) == address(0)) {
            revert WrongAddress(_registry, "Invalid StakingStorage address");
        }

        stakingStorage = _registry.stakingStorageContract;
        _pause();
        _transferOwnership(multisig);
    }

    /**
     * @param _registry Registry contract address
     * @param _storage Staking Storage contract address
     */
    function init(Registry _registry, IERC20 _storage) external onlyOwner {
        if (address(_registry) == address(0)) {
            revert WrongAddress(_registry, "Invalid Registry address");
        }
        if (address(_storage) == address(0)) {
            revert WrongAddress(_registry, "Invalid StakingStorage address");
        }

        stakingStorage = _registry.stakingStorageContract;
        _unpause();
        _transferOwnership(multisig);
        initialized = true;
    }

    /** ----------------------------------
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @notice
     * @notice
     * @notice
     * @notice
     *
     * @dev
     *
     * @param
     */
    function updateHistory(
        address token,
        address wallet,
        uint256 _amount
    ) public onlyManager {}

    /** ----------------------------------
     * ! CRUD functions
     * ----------------------------------- */

    /**
     * @notice
     * @notice
     * @notice
     * @notice
     *
     * @dev
     *
     * @param _token - which token to stake
     * @param _wallet - user address
     * @param _amount - amount of tokens to stake
     */
    function updateHistory(
        address _token,
        address _wallet,
        uint256 _amount
    ) public onlyManager {}
}

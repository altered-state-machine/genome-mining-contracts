// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Tokens.sol";
import "./Registry.sol";
import "./Staking.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Storage contract
 */
contract StakingStorage is
    Tokens,
    IStaking,
    PermissionControl,
    Util,
    Ownable,
    Pausable
{
    address private _multisig;
    bool private initialized = false;

    // Inrementing stake Id used to record history
    mapping(address => uint16) public stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint16 => Stake)) public stakeHistory;

    /**
     * @param multisig Multisig address as the contract owner
     */
    constructor(address multisig) {
        if (address(multisig) == address(0)) {
            revert WrongAddress(multisig, "Invalid Multisig address");
        }
        _multisig = multisig;
        _pause();
    }

    /**
     * @param registry Registry contract address
     * @param staking Staking contract address
     */
    function init(address registry, address staking) external onlyOwner {
        require(
            initialized == false,
            "It's too late. The contract has already been initialized."
        );
        if (!_isContract(registry)) {
            revert WrongAddress(registry, "Invalid Registry address");
        }
        if (!_isContract(staking)) {
            revert WrongAddress(staking, "Invalid Staking address");
        }

        _setupRole(REGISTRY_ROLE, registry);
        _setupRole(MANAGER_ROLE, staking);
        _unpause();
        _transferOwnership(_multisig);

        initialized = true;
    }

    /**
     * @notice
     * @notice
     * @notice
     * @notice
     *
     * @dev
     *
     * @param token - address of token to stake
     * @param wallet - user address
     * @param amount - amount of tokens to stake
     * @return stakeID
     */
    function updateHistory(
        Token token,
        address wallet,
        uint256 amount
    ) public onlyManager returns (uint256) {
        return 123;
    }
}

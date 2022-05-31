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
contract StakingStorage is Tokens, IStaking, PermissionControl, Util, Ownable, Pausable {
    address private _multisig;
    bool private initialized = false;

    uint256 private _totalCounter;
    // Incremented total stakes counter, pointing to the address of who staked
    mapping(uint256 => address) private _stakes; // _totalStakesCounter => user address
    // Incrementing stake Id used to record history
    mapping(address => uint256) private _stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint256 => Stake)) private _stakeHistory;

    /**
     * @param multisig Multisig address as the contract owner
     */
    constructor(address multisig) {
        if (address(multisig) == address(0)) {
            revert WrongAddress(multisig, INVALID_MULTISIG);
        }
        _multisig = multisig;
        _pause();
    }

    /**
     * @param registry Registry contract address
     * @param staking Staking contract address
     */
    function init(address registry, address staking) external onlyOwner {
        require(initialized == false, ALREADY_INITIALIZED);
        if (!_isContract(registry)) {
            revert WrongAddress(registry, INVALID_REGISTRY);
        }
        if (!_isContract(staking)) {
            revert WrongAddress(staking, INVALID_STAKING_LOGIC);
        }

        // we need Registry to allow it to change a Manager
        _setupRole(REGISTRY_ROLE, registry);
        // we allow Manager to save into the storage
        _setupRole(MANAGER_ROLE, staking);
        _unpause();
        _transferOwnership(_multisig);

        initialized = true;
    }

    /**
     * @notice Saving stakes into storage.
     * @notice Function can be called only manager
     * @notice
     * @notice
     *
     * @dev
     *
     * @param token - address of token to stake
     * @param addr - user address
     * @param amount - amount of tokens to stake
     * @return stakeID
     */
    function updateHistory(
        Token token,
        address addr,
        uint256 amount
    ) public onlyRole(MANAGER_ROLE) returns (uint256) {
        if (address(addr) == address(0)) revert WrongAddress(addr, WRONG_ADDRESS);
        if (amount <= 0) revert WrongParameter(WRONG_AMOUNT);

        _stakes[++_totalCounter] = addr; // incrementing total stakes counter

        uint128 time = uint128(block.timestamp); // not more that 1 stake per second
        Stake memory newStake = Stake(token, time, amount);
        uint256 userStakeId = ++_stakeIds[addr]; // ++i cheaper than i++, so, stakeIds starts from 1
        _stakeHistory[addr][userStakeId] = newStake;
        return userStakeId;
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    function getTotalStakesCounter() public view returns (uint256) {
        return _totalCounter;
    }

    function getStake(address addr, uint256 id) public view returns (Stake memory) {
        return _stakeHistory[addr][id];
    }

    function getUserLastStakeId(address addr) public view returns (uint256) {
        return _stakeIds[addr];
    }

    function getLastStakeId() public view returns (uint256) {
        return _stakeIds[_stakes[_totalCounter]];
    }
}

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

    uint16 private _totalStakesCounter;
    // Incremented total stakes counter, pointing to the address of who staked
    mapping(uint16 => address) public allStakeIds; // _totalStakesCounter => user address
    // Incrementing stake Id used to record history
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
    ) public onlyManager returns (uint256) {
        if (address(addr) == address(0))
            revert WrongAddress(addr, "Wallet is missed");

        if (amount <= 0) revert WrongParameter("Amount should be > 0");

        allStakeIds[++_totalStakesCounter] = addr; // incrementing total stakes counter

        uint128 time = uint128(block.timestamp); // not more that 1 stake per second
        Stake memory newStake = Stake(token, time, amount);
        uint16 userStakeId = ++stakeIds[addr]; // ++i cheaper than i++, so, stakeIds starts from 1
        stakeHistory[addr][userStakeId] = newStake;
        return userStakeId;
    }
}

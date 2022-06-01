// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Tokens.sol";
import "./Registry.sol";
import "./helpers/Util.sol";
import "./StakingStorage.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Logic contract
 */

contract Staking is IStaking, TimeConstants, Util, PermissionControl, Pausable {
    using SafeERC20 for IERC20;

    StakingStorage private storage_;
    Tokens private tokens_;
    bool private initialized = false;
    uint256 private _totalTokens;

    mapping(uint256 => IERC20) public tokens; // asto - 1, lp - 2

    /**
     * @dev 1. Contracts addresses for the roles are not known yet
     * @dev 2. Do setup before transfer ownership to the DAO's multisig contract
     */
    constructor() {
        address deployer = msg.sender;
        _setupRole(REGISTRY_ROLE, deployer);
        _setupRole(MANAGER_ROLE, deployer);
        _pause();
    }

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only Manager is allowed to call admin functions
     * @dev only Registry is allowed to update permissions - to reduce amount of DAO votings
     *
     * @param multisig Multisig address as the contract owner
     * @param registry Registry contract address
     * @param stakingStorage Staking contract address
     */
    function init(
        address multisig,
        address registry,
        address stakingStorage,
        Tokens tokensContract
    ) public onlyRole(MANAGER_ROLE) {
        require(initialized == false, ALREADY_INITIALIZED);

        if (!_isContract(multisig)) revert ContractError(INVALID_MULTISIG);
        if (!_isContract(registry)) revert ContractError(INVALID_REGISTRY);
        if (!_isContract(stakingStorage)) revert ContractError(INVALID_STAKING_STORAGE);

        storage_ = StakingStorage(stakingStorage);
        tokens_ = Tokens(tokensContract);
        uint256 totalTokens = tokens_.getTotalTokens();
        for (uint256 i = 0; i < totalTokens; ++i) {
            tokens[i] = tokens_.tokens(i);
        }

        _updateRole(REGISTRY_ROLE, registry);
        _updateRole(MANAGER_ROLE, multisig);
        _grantRole(MANAGER_ROLE, registry);

        _unpause();
        initialized = true;
    }

    /** ----------------------------------
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @notice Withdraw tokens left in the contract to specified address
     * @param tokenId - ID of token to stake
     * @param recipient recipient of the transfer
     * @param amount Token amount to withdraw
     */
    function withdraw(
        uint256 tokenId,
        address recipient,
        uint256 amount
    )
        public
        whenPaused // when contract is paused ONLY
        onlyRole(MANAGER_ROLE)
    {
        if (!_isContract(address(tokens[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (address(recipient) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (tokens[tokenId].balanceOf(address(this)) <= 0) revert InvalidInput(INSUFFICIENT_BALANCE);

        tokens[tokenId].safeTransfer(recipient, amount);
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @notice Staking is a process of locking your tokens in this contract.
     * @notice Details of the stake are to be stored and used for calculations
     * @notice what time your tokens are stay staked.
     * @notice You can always unlock your token. See `unstake()`.
     *
     * @dev Emit `Staked` event when successful, with address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function stake(uint256 tokenId, uint256 amount) external whenNotPaused {
        if (!_isContract(address(tokens[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (amount <= 0) revert InvalidInput(WRONG_AMOUNT);
        address user = msg.sender;
        uint256 userBalance = tokens[tokenId].balanceOf(user);
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        // _beforeTokenTransfer(...);

        tokens[tokenId].approve(address(this), amount);
        tokens[tokenId].safeTransferFrom(user, address(this), amount);
        storage_.updateHistory(tokenId, user, amount);
        emit Staked(user, block.timestamp, amount);
    }

    /**
     * @notice
     * @notice
     *
     * @dev Emit `UnStaked` event when successful, with address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function unStake(uint256 tokenId, uint256 amount) external {
        if (!_isContract(address(tokens[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (amount <= 0) revert InvalidInput(WRONG_AMOUNT);

        address user = msg.sender;
        uint256 id = storage_.getUserLastStakeId(user);
        if (id == 0) revert InvalidInput(NO_STAKES);
        uint256 userBalance = (storage_.getStake(user, id)).amount;
        uint256 newAmount = userBalance - amount;

        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        storage_.updateHistory(tokenId, user, newAmount);

        // _beforeTokenTransfer(...);
        tokens[tokenId].safeTransfer(user, amount);
        emit UnStaked(user, block.timestamp, amount);
    }

    /**
     * @notice Returns the total amount of tokens staked by all users
     * @param tokenId ASTO/LBA/LP
     * @return amount of tokens staked in the contract, uint256
     */
    function getTotalValueLocked(uint256 tokenId) external returns (uint256) {}

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    function getStorageAddress() public view returns (address) {
        return address(storage_);
    }

    /** ----------------------------------
     * ! Controls
     * ----------------------------------- */

    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function addToken(IERC20 token) external onlyRole(REGISTRY_ROLE) {
        tokens[++_totalTokens] = token;
    }
}

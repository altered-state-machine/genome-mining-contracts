// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./Controller.sol";
import "./Staking.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Storage contract
 */
contract StakingStorage is IStaking, PermissionControl, Util, Pausable {
    bool private _initialized = false;

    // Incrementing stake Id used to record history
    mapping(address => uint256) private _stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint256 => Stake)) private _stakeHistory;

    constructor(address controller) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        _setupRole(CONTROLLER_ROLE, controller);
        _setupRole(STAKER_ROLE, controller);
        _pause();
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @notice Saving stakes into storage.
     * @notice Function can be called only manager
     *
     * @param addr - user address
     * @param amount - amount of tokens to stake
     * @return stakeID
     */
    function updateHistory(address addr, uint256 amount) public onlyRole(STAKER_ROLE) returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);

        uint128 time = uint128(block.timestamp);
        Stake memory newStake = Stake(time, amount);
        uint256 userStakeId = ++_stakeIds[addr]; // ++i cheaper than i++, so, _stakeHistory[addr] starts from 1
        _stakeHistory[addr][userStakeId] = newStake;
        return userStakeId;
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    function getStake(address addr, uint256 id) public view returns (Stake memory) {
        return _stakeHistory[addr][id];
    }

    function getHistory(address addr, uint256 endTime) public view returns (Stake[] memory) {
        uint256 totalStakes = _stakeIds[addr];

        Stake[] memory stakes = new Stake[](totalStakes); // suboptimal - it could be larger than needed, when endTime is lesser than current time

        // _stakeHistory[addr] starts from 1, see `updateHistory`
        for (uint256 i = 1; i < totalStakes + 1; i++) {
            Stake memory stake = _stakeHistory[addr][i];
            if (stake.time <= endTime) stakes[i - 1] = stake;
            else {
                // shortening array before returning
                Stake[] memory res = new Stake[](i - 1);
                for (uint256 j = 0; j < res.length; j++) res[j] = stakes[j];
                return res;
            }
        }
        return stakes;
    }

    function getUserLastStakeId(address addr) public view returns (uint256) {
        return _stakeIds[addr];
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only Staker is allowed to save into this storage
     * @dev only Controller is allowed to update permissions - to reduce amount of DAO votings
     * @dev
     *
     * @param controller Controller contract address
     * @param stakingLogic Staking contract address
     */
    function init(address stakingLogic) public onlyRole(CONTROLLER_ROLE) {
        require(_initialized == false, ALREADY_INITIALIZED);
        _updateRole(STAKER_ROLE, stakingLogic);
        _unpause();
        _initialized = true;
    }

    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _updateRole(CONTROLLER_ROLE, newController);
    }

    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IConverter.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Converter Logic contract
 */
contract Converter is IConverter, TimeConstants, Util, PermissionControl, Pausable, Ownable {
    address private _multisig;
    bool private initialized = false;

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
     * @notice Calculate the available energy for `addr`
     *
     * @param addr - wallet address to calculate
     * @return Energy avaiable
     */
    function calculateEnergy(address addr) external returns (uint256) {}

    /**
     * @notice Estimate energy can be generated per day for all stakes
     *
     * @return Energy can be generated
     */
    function estimateEnergy() public view returns (uint256) {}

    /**
     * @notice Get total energy balance in storage contract
     *
     * @return Total energy balance
     */
    function getTotalEnergy() public view returns (uint256) {}

    /**
     * @notice Get user share of the whole energy pool
     *
     * @param periodId - the periodId to calculate
     * @return Share number
     */
    function getPeriodShare(uint256 periodId) public view returns (uint256) {}

    /**
     * @notice Transfer energy to `recipient`
     *
     * @param recipient - the contract address to receive the energy
     * @param amount - the amount of energy to transfer
     */
    function useEnergy(address recipient, uint256 amount) external {}

    /** ----------------------------------
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @param registry Registry contract address
     * @param energyStorage Energy storage contract address
     * @param stakingStorage Staking storage contract address
     */
    function init(
        address registry,
        address energyStorage,
        address stakingStorage
    ) external onlyOwner {
        require(!initialized, "The contract has already been initialized.");
        if (!_isContract(registry)) {
            revert WrongAddress(registry, "Invalid Registry address.");
        }
        if (!_isContract(energyStorage)) {
            revert WrongAddress(energyStorage, "Invalid Energy Storage address,");
        }
        if (!_isContract(stakingStorage)) {
            revert WrongAddress(stakingStorage, "Invalid Staking Storage address,");
        }

        _setupRole(REGISTRY_ROLE, registry);
        _unpause();
        _transferOwnership(_multisig);

        initialized = true;

        // TODO setup Storage contracts
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

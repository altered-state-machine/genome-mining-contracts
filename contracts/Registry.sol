// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Staking.sol";
import "./StakingStorage.sol";
import "./Converter.sol";
import "./ConverterStorage.sol";
import "./helpers/PermissionControl.sol";
import "./helpers/Util.sol";

/**
 * @dev ASM Genome Mining - Registry contract
 * @notice We use this contract to manage contracts addresses
 * @notice when we need to update some of them.
 */
contract Registry is Util, PermissionControl {
    Registry public registryContract;
    Staking public stakingLogicContract;
    StakingStorage public stakingStorageContract;
    Converter public converterLogicContract;
    ConverterStorage public converterStorageContract;

    address private _multisig;

    constructor(
        address multisig,
        address stakingLogic,
        address stakingStorage,
        address converterLogic,
        address converterStorage
    ) {
        if (!_isContract(multisig)) revert InvalidInput(INVALID_MULTISIG);
        if (!_isContract(stakingLogic)) revert InvalidInput(INVALID_STAKING_LOGIC);
        if (!_isContract(stakingStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(converterLogic)) revert InvalidInput(INVALID_CONVERTER_LOGIC);
        if (!_isContract(converterStorage)) revert InvalidInput(INVALID_CONVERTER_STORAGE);

        _changeContracts(stakingLogic, stakingStorage, converterLogic, converterStorage, address(this));
        _setupRole(MANAGER_ROLE, multisig);
        _multisig = multisig;
    }

    function changeContracts(
        address stakingLogic,
        address stakingStorage,
        address converterLogic,
        address converterStorage,
        address registry
    ) public onlyRole(MANAGER_ROLE) {
        _changeContracts(stakingLogic, stakingStorage, converterLogic, converterStorage, registry);
    }

    function _changeContracts(
        address stakingLogic,
        address stakingStorage,
        address converterLogic,
        address converterStorage,
        address registry
    ) internal {
        if (_isContract(stakingLogic)) {
            stakingLogicContract = Staking(stakingLogic);
            // StakingStorage.updateManager(stakingLogic);
        }

        if (_isContract(stakingStorage)) {
            stakingStorageContract = StakingStorage(stakingStorage);
            // stakingLogicContract.init(address(this), stakingStorage);
        }

        if (_isContract(converterLogic)) {
            converterLogicContract = Converter(converterLogic);
            // StakingStorage.updateConverter(converterLogic);
            // ConverterStorage.updateManager(converterLogic);
        }
        if (_isContract(converterStorage)) {
            converterStorageContract = ConverterStorage(converterStorage);
        }

        if (_isContract(registry)) {
            registryContract = Registry(registry);
            // StakingStorage.updateRegistry(registry);
            // ConverterStorage.updateRegistry(registry);
        }
    }

    function setMultisig(address multisig) public onlyRole(MANAGER_ROLE) {
        _multisig = multisig;
        _updateRole(MANAGER_ROLE, multisig);
    }

    function getMultisig() public view returns (address) {
        return _multisig;
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        stakingLogicContract.pause();
        stakingStorageContract.pause();
        // converterLogicContract.pause();
        // converterStorageContract.pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        stakingLogicContract.unpause();
        stakingStorageContract.unpause();
        // converterLogicContract.unpause();
        // converterStorageContract.unpause();
    }
}

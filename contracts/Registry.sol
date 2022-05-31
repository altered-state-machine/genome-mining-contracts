// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
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
contract Registry is Util, Ownable, PermissionControl {
    address public multisig;

    Registry public registryContract;
    Staking public stakingLogicContract;
    StakingStorage public stakingStorageContract;
    Converter public converterLogicContract;
    ConverterStorage public converterStorageContract;

    constructor(
        address _multisig,
        address _stakingLogic,
        address _stakingStorage,
        address _converterLogic,
        address _converterStorage
    ) {
        changeContracts(_stakingLogic, _stakingStorage, _converterLogic, _converterStorage, address(this));

        if (address(_multisig) == address(0)) revert WrongAddress(_multisig, INVALID_MULTISIG);
        if (address(_stakingLogic) == address(0)) revert WrongAddress(_stakingLogic, INVALID_STAKING_LOGIC);
        if (address(_stakingStorage) == address(0)) revert WrongAddress(_stakingStorage, INVALID_STAKING_STORAGE);
        if (address(_converterLogic) == address(0)) revert WrongAddress(_converterLogic, INVALID_CONVERTER_LOGIC);
        if (address(_converterStorage) == address(0)) revert WrongAddress(_converterStorage, INVALID_CONVERTER_STORAGE);

        multisig = _multisig;
        transferOwnership(_multisig);
    }

    function changeContracts(
        address _stakingLogic,
        address _stakingStorage,
        address _converterLogic,
        address _converterStorage,
        address _registry
    ) public onlyOwner {
        if (address(_stakingLogic) != address(0)) {
            stakingLogicContract = Staking(_stakingLogic);
            // StakingStorage.updateManager(_stakingLogic);
        }

        if (address(_stakingStorage) != address(0)) {
            stakingStorageContract = StakingStorage(_stakingStorage);
            // stakingLogicContract.init(address(this), _stakingStorage);
        }

        if (address(_converterLogic) != address(0)) {
            converterLogicContract = Converter(_converterLogic);
            // StakingStorage.updateConverter(_converterLogic);
            // ConverterStorage.updateManager(_converterLogic);
        }
        if (address(_converterStorage) != address(0)) {
            converterStorageContract = ConverterStorage(_converterStorage);
        }

        if (address(_registry) != address(0)) {
            registryContract = Registry(_registry);
            // StakingStorage.updateRegistry(_registry);
            // ConverterStorage.updateRegistry(_registry);
        }
    }
}

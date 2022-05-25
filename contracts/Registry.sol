// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Staking.sol";
import "./StakingStorage.sol";
import "./Converter.sol";
import "./ConverterStorage.sol";
import "./Util.sol";

/**
 * @dev ASM Genome Mining - Tokens
 * TOKENS:
 * ------ ASTO ------
 * mainnet: 0x823556202e86763853b40e9cDE725f412e294689
 * rinkeby: ...
 * ------ LBA LP ------
 * mainnet: ..
 * rinkeby: ...
 * ------ LP ------
 * mainnet: ..
 * rinkeby: ...
 */
contract Registry is Util, Ownable {
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
        changeContracts(
            _stakingLogic,
            _stakingStorage,
            _converterLogic,
            _converterStorage,
            address(this)
        );

        if (!_isContract(_multisig)) {
            revert WrongAddress(_multisig, "Wrong multisig address");
        }
        if (!_isContract(_stakingLogic)) {
            revert WrongAddress(_stakingLogic, "Wrong staking logic address");
        }
        if (!_isContract(_stakingStorage)) {
            revert WrongAddress(
                _stakingStorage,
                "Wrong staking storage address"
            );
        }
        if (!_isContract(_converterLogic)) {
            revert WrongAddress(
                _converterLogic,
                "Wrong converter logic address"
            );
        }
        if (!_isContract(_converterStorage)) {
            revert WrongAddress(
                _converterStorage,
                "Wrong converter storage address"
            );
        }

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

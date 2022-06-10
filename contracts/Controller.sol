// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Staking.sol";
import "./StakingStorage.sol";
import "./LBAEnergyConverter.sol";
import "./Converter.sol";
import "./EnergyStorage.sol";
import "./helpers/PermissionControl.sol";
import "./helpers/Util.sol";

/**
 * @dev ASM Genome Mining - Registry contract
 * @notice We use this contract to manage contracts addresses
 * @notice when we need to update some of them.
 */
contract Controller is Util, PermissionControl {
    Controller private _controller;
    Staking private _stakingLogic;
    StakingStorage private _astoStorage;
    StakingStorage private _lpStorage;
    Converter private _converter;
    LBAEnergyConverter private _lbaConverter;
    EnergyStorage private _energyStorage;
    IERC20 private _astoToken;
    IERC20 private _lpToken;

    address private _manager; // DAO multisig contract, public for auto getter

    event ContractUpgraded(uint256 timestamp, string contractName, address oldAddress, address newAddress);

    constructor(address multisig) {
        if (!_isContract(multisig)) revert InvalidInput(INVALID_MULTISIG);
        _manager = multisig;
        _setupRole(MANAGER_ROLE, multisig); // `RoleGranted` event will be emitted
    }

    function init(
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address lbaConverter,
        address converter,
        address energyStorage
    ) external onlyRole(MANAGER_ROLE) {
        if (!_isContract(astoToken)) revert InvalidInput(INVALID_ASTO_CONTRACT);
        if (!_isContract(astoStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(lpToken)) revert InvalidInput(INVALID_LP_CONTRACT);
        if (!_isContract(lpStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(stakingLogic)) revert InvalidInput(INVALID_STAKING_LOGIC);
        if (!_isContract(lbaConverter)) revert InvalidInput(INVALID_LBA_CONVERTER);
        if (!_isContract(converter)) revert InvalidInput(INVALID_CONVERTER_LOGIC);
        if (!_isContract(energyStorage)) revert InvalidInput(INVALID_ENERGY_STORAGE);

        // Saving addresses on init:
        _astoToken = IERC20(astoToken);
        _astoStorage = StakingStorage(astoStorage);
        _lpToken = IERC20(lpToken);
        _lpStorage = StakingStorage(lpStorage);
        _stakingLogic = Staking(stakingLogic);
        _lbaConverter = LBAEnergyConverter(lbaConverter);
        _converter = Converter(converter);
        _energyStorage = EnergyStorage(energyStorage);
        _controller = Controller(this);

        // Initializing contracts
        _upgradeContracts(
            address(this),
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            lbaConverter,
            converter,
            energyStorage
        );
    }

    /** ----------------------------------
     * ! Private functions | Setters
     * ----------------------------------- */

    /**
     * @notice Each contract has own params to initialize
     * @notice Contracts with no address specified will be skipped
     * @dev Internal functions, can be called from constructor OR
     * @dev after authentication by the public function `upgradeContracts()`
     */
    function _upgradeContracts(
        address controller,
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address lbaConverter,
        address converter,
        address energyStorage
    ) private {
        if (_isContract(controller)) _setController(controller);
        if (_isContract(astoToken)) _setAstoToken(astoToken);
        if (_isContract(astoStorage)) _setAstoStorage(astoStorage);
        if (_isContract(lpToken)) _setLpToken(lpToken);
        if (_isContract(lpStorage)) _setLpStorage(lpStorage);
        if (_isContract(stakingLogic)) _setStakingLogic(stakingLogic);
        if (_isContract(lbaConverter)) _setLbaConverter(lbaConverter);
        if (_isContract(energyStorage)) _setEnergyStorage(energyStorage);
        if (_isContract(converter)) _setConverter(converter);
    }

    function _setManager(address multisig) private {
        _manager = multisig;
        _updateRole(MANAGER_ROLE, multisig);
    }

    function _setController(address newContract) private {
        address oldContract = address(_controller);
        _stakingLogic.setController(address(_controller));
        _astoStorage.setController(address(_controller));
        _lpStorage.setController(address(_controller));
        _converter.setController(address(_controller));
        _energyStorage.setController(address(_controller));
        _lbaConverter.setController(address(_controller));

        emit ContractUpgraded(block.timestamp, "Controller", oldContract, newContract);
    }

    function _setStakingLogic(address newContract) private {
        address oldContract = address(_stakingLogic);
        _stakingLogic = Staking(newContract);
        _stakingLogic.init(
            address(_manager),
            IERC20(_astoToken),
            address(_astoStorage),
            IERC20(_lpToken),
            address(_lpStorage)
        );
        emit ContractUpgraded(block.timestamp, "Staking Logic", oldContract, newContract);
    }

    function _setAstoToken(address newContract) private {
        address oldContract = address(_astoToken);
        _astoToken = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "ASTO Token", oldContract, newContract);
    }

    function _setAstoStorage(address newContract) private {
        address oldContract = address(_astoStorage);
        _astoStorage = StakingStorage(newContract);
        _astoStorage.init(address(_stakingLogic));
        emit ContractUpgraded(block.timestamp, "ASTO Staking Storage", oldContract, newContract);
    }

    function _setLpToken(address newContract) private {
        address oldContract = address(_lpToken);
        _lpToken = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "LP Token", oldContract, newContract);
    }

    function _setLpStorage(address newContract) private {
        address oldContract = address(_lpStorage);
        _lpStorage = StakingStorage(newContract);
        _lpStorage.init(address(_stakingLogic));
        emit ContractUpgraded(block.timestamp, "LP Staking Storage", oldContract, newContract);
    }

    function _setConverter(address newContract) private {
        address oldContract = address(_converter);
        _converter = Converter(newContract);
        _converter.init(address(_manager), address(_energyStorage), address(_stakingLogic));
        _lbaConverter.setConverter(newContract);
        emit ContractUpgraded(block.timestamp, "Converter Logic", oldContract, newContract);
    }

    function _setLbaConverter(address newContract) private {
        address oldContract = address(_lbaConverter);
        _lbaConverter = LBAEnergyConverter(newContract);
        _lbaConverter.init(address(_manager), address(_converter));
        emit ContractUpgraded(block.timestamp, "LBA Converter Logic", oldContract, newContract);
    }

    function _setEnergyStorage(address newContract) private {
        address oldContract = address(_energyStorage);
        _energyStorage = EnergyStorage(newContract);
        _energyStorage.init(address(_converter));
        emit ContractUpgraded(block.timestamp, "Energy Storage", oldContract, newContract);
    }

    /** ----------------------------------
     * ! External functions | Manager Role
     * ----------------------------------- */

    /**
     * @notice The way to upgrade contracts
     * @notice Only Manager address (multisig wallet) has access to upgrade
     * @notice All parameters are optional
     */
    function upgradeContracts(
        address controller,
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address lbaConverter,
        address converter,
        address energyStorage
    ) external onlyRole(MANAGER_ROLE) {
        _upgradeContracts(
            controller,
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            lbaConverter,
            converter,
            energyStorage
        );
    }

    function setManager(address multisig) external onlyRole(MANAGER_ROLE) {
        _setManager(multisig);
        _stakingLogic.setManager(multisig);
        _converter.setManager(multisig);
    }

    function setController(address newContract) external onlyRole(MANAGER_ROLE) {
        _setController(newContract);
    }

    function setStakingLogic(address newContract) external onlyRole(MANAGER_ROLE) {
        _setStakingLogic(newContract);
    }

    function setAstoStorage(address newContract) external onlyRole(MANAGER_ROLE) {
        _setAstoStorage(newContract);
    }

    function setLpStorage(address newContract) external onlyRole(MANAGER_ROLE) {
        _setLpStorage(newContract);
    }

    function setConverter(address newContract) external onlyRole(MANAGER_ROLE) {
        _setConverter(newContract);
    }

    function setLbaConverter(address newContract) external onlyRole(MANAGER_ROLE) {
        _setLbaConverter(newContract);
    }

    function setEnergyStorage(address newContract) external onlyRole(MANAGER_ROLE) {
        _setEnergyStorage(newContract);
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        _stakingLogic.pause();
        _converter.pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _stakingLogic.unpause();
        _converter.unpause();
    }

    /** ----------------------------------
     * ! Public functions | Getters
     * ----------------------------------- */

    function getController() public view returns (address) {
        return address(this);
    }

    function getManager() public view returns (address) {
        return _manager;
    }

    function getStakingLogic() public view returns (address) {
        return address(_stakingLogic);
    }

    function getAstoStorage() public view returns (address) {
        return address(_astoStorage);
    }

    function getLpStorage() public view returns (address) {
        return address(_lpStorage);
    }

    function getConverter() public view returns (address) {
        return address(_converter);
    }

    function getLbaConverter() public view returns (address) {
        return address(_lbaConverter);
    }

    function getEnergyStorage() public view returns (address) {
        return address(_energyStorage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Staking.sol";
import "./StakingStorage.sol";
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
    Converter private _converterLogic;
    EnergyStorage private _energyStorage;
    EnergyStorage private _lbaEnergyStorage;
    IERC20 private _astoToken;
    IERC20 private _lpToken;
    address private _dao;
    address private _multisig;

    event ContractUpgraded(uint256 timestamp, string contractName, address oldAddress, address newAddress);

    constructor(address multisig) {
        if (!_isContract(multisig)) revert InvalidInput(INVALID_MULTISIG);
        /**
         * MULTISIG_ROLE is ONLY used for:
         * - initalisation controller
         * - setting periods (mining cycles) for the Converter contract
         */
        _setupRole(MULTISIG_ROLE, multisig);
        _setupRole(DAO_ROLE, multisig);
        _multisig = multisig;
    }

    function init(
        address dao,
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage,
        address lbaEnergyStorage
    ) external onlyRole(MULTISIG_ROLE) {
        if (!_isContract(dao)) revert InvalidInput(INVALID_DAO);
        if (!_isContract(astoToken)) revert InvalidInput(INVALID_ASTO_CONTRACT);
        if (!_isContract(astoStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(lpToken)) revert InvalidInput(INVALID_LP_CONTRACT);
        if (!_isContract(lpStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(stakingLogic)) revert InvalidInput(INVALID_STAKING_LOGIC);
        if (!_isContract(converterLogic)) revert InvalidInput(INVALID_CONVERTER_LOGIC);
        if (!_isContract(energyStorage)) revert InvalidInput(INVALID_ENERGY_STORAGE);
        if (!_isContract(lbaEnergyStorage)) revert InvalidInput(INVALID_ENERGY_STORAGE);

        _updateRole(DAO_ROLE, dao); // remove MULTISIG address from DAO_ROLE

        // Saving addresses on init:
        _dao = dao;
        _astoToken = IERC20(astoToken);
        _astoStorage = StakingStorage(astoStorage);
        _lpToken = IERC20(lpToken);
        _lpStorage = StakingStorage(lpStorage);
        _stakingLogic = Staking(stakingLogic);
        _converterLogic = Converter(converterLogic);
        _energyStorage = EnergyStorage(energyStorage);
        _lbaEnergyStorage = EnergyStorage(lbaEnergyStorage);
        _controller = Controller(this);

        // Initializing contracts
        _upgradeContracts(
            address(this),
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            converterLogic,
            energyStorage,
            lbaEnergyStorage
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
        address converterLogic,
        address energyStorage,
        address lbaEnergyStorage
    ) private {
        if (_isContract(astoToken)) _setAstoToken(astoToken);
        if (_isContract(astoStorage)) _setAstoStorage(astoStorage);
        if (_isContract(lpToken)) _setLpToken(lpToken);
        if (_isContract(lpStorage)) _setLpStorage(lpStorage);
        if (_isContract(stakingLogic)) _setStakingLogic(stakingLogic);
        if (_isContract(energyStorage)) _setEnergyStorage(energyStorage);
        if (_isContract(lbaEnergyStorage)) _setLBAEnergyStorage(lbaEnergyStorage);
        if (_isContract(converterLogic)) _setConverterLogic(converterLogic);
        if (_isContract(controller)) _setController(controller);
    }

    function _setDao(address dao) private {
        if (dao != _dao) {
            _dao = dao;
            _updateRole(DAO_ROLE, dao);
            _stakingLogic.setDao(dao);
            _converterLogic.setDao(dao);
        }
        _grantRole(MULTISIG_ROLE, dao);
    }

    function _setMultisig(address multisig) private {
        _multisig = multisig;
        _updateRole(MULTISIG_ROLE, multisig);
        _setDao(_dao); // to grant MULTISIG_ROLE to DAO (DAO itself won't be updated)
        _converterLogic.setMultisig(multisig, _dao);
    }

    function _setController(address newContract) private {
        _stakingLogic.setController(address(_controller));
        _astoStorage.setController(address(_controller));
        _lpStorage.setController(address(_controller));
        _converterLogic.setController(address(_controller));
        _energyStorage.setController(address(_controller));
        _lbaEnergyStorage.setController(address(_controller));
        emit ContractUpgraded(block.timestamp, "Controller", address(this), newContract);
    }

    function _setStakingLogic(address newContract) private {
        _stakingLogic = Staking(newContract);
        _stakingLogic.init(
            address(_dao),
            IERC20(_astoToken),
            address(_astoStorage),
            IERC20(_lpToken),
            address(_lpStorage)
        );
        _astoStorage.setConsumer(address(newContract));
        _lpStorage.setConsumer(address(newContract));
        emit ContractUpgraded(block.timestamp, "Staking Logic", address(this), newContract);
    }

    function _setAstoToken(address newContract) private {
        _astoToken = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "ASTO Token", address(this), newContract);
    }

    function _setAstoStorage(address newContract) private {
        _astoStorage = StakingStorage(newContract);
        _astoStorage.init(address(_stakingLogic));
        emit ContractUpgraded(block.timestamp, "ASTO Staking Storage", address(this), newContract);
    }

    function _setLpToken(address newContract) private {
        _lpToken = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "LP Token", address(this), newContract);
    }

    function _setLpStorage(address newContract) private {
        _lpStorage = StakingStorage(newContract);
        _lpStorage.init(address(_stakingLogic));
        emit ContractUpgraded(block.timestamp, "LP Staking Storage", address(this), newContract);
    }

    function _setConverterLogic(address newContract) private {
        _converterLogic = Converter(newContract);
        _converterLogic.init(
            address(_dao),
            address(_multisig),
            address(_energyStorage),
            address(_lbaEnergyStorage),
            address(_stakingLogic)
        );
        _lbaEnergyStorage.setConsumer(address(newContract));
        _energyStorage.setConsumer(address(newContract));
        emit ContractUpgraded(block.timestamp, "Converter Logic", address(this), newContract);
    }

    function _setEnergyStorage(address newContract) private {
        _energyStorage = EnergyStorage(newContract);
        _energyStorage.init(address(_converterLogic));
        emit ContractUpgraded(block.timestamp, "Energy Storage", address(this), newContract);
    }

    function _setLBAEnergyStorage(address newContract) private {
        _lbaEnergyStorage = EnergyStorage(newContract);
        _lbaEnergyStorage.init(address(_converterLogic));
        emit ContractUpgraded(block.timestamp, "LBA Energy Storage", address(this), newContract);
    }

    function _setMintingContract(address newContract) private {
        _converterLogic.setConsumer(address(newContract));
        emit ContractUpgraded(
            block.timestamp,
            "Converter Logic - new Minting contract set",
            address(this),
            newContract
        );
    }

    /** ----------------------------------
     * ! External functions | Manager Role
     * ----------------------------------- */

    /**
     * @notice The way to upgrade contracts
     * @notice Only Manager address (_dao wallet) has access to upgrade
     * @notice All parameters are optional
     */
    function upgradeContracts(
        address controller,
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address energyStorage,
        address lbaEnergyStorage
    ) external onlyRole(DAO_ROLE) {
        _upgradeContracts(
            controller,
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            converterLogic,
            energyStorage,
            lbaEnergyStorage
        );
    }

    function setDao(address dao) external onlyRole(DAO_ROLE) {
        _setDao(dao);
    }

    function setMultisig(address multisig) external onlyRole(DAO_ROLE) {
        _setMultisig(multisig);
    }

    function setController(address newContract) external onlyRole(DAO_ROLE) {
        _setController(newContract);
    }

    function setStakingLogic(address newContract) external onlyRole(DAO_ROLE) {
        _setStakingLogic(newContract);
    }

    function setAstoStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setAstoStorage(newContract);
    }

    function setLpStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setLpStorage(newContract);
    }

    function setConverterLogic(address newContract) external onlyRole(DAO_ROLE) {
        _setConverterLogic(newContract);
    }

    function setEnergyStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setEnergyStorage(newContract);
    }

    function setLBAEnergyStorage(address newContract) external onlyRole(DAO_ROLE) {
        _setLBAEnergyStorage(newContract);
    }

    function setMintingContract(address newContract) external onlyRole(DAO_ROLE) {
        _setMintingContract(newContract);
    }

    // DAO and MULTISIG can call this function
    function pause() external onlyRole(MULTISIG_ROLE) {
        _stakingLogic.pause();
        _converterLogic.pause();
    }

    // DAO and MULTISIG can call this function
    function unpause() external onlyRole(MULTISIG_ROLE) {
        _stakingLogic.unpause();
        _converterLogic.unpause();
    }

    /** ----------------------------------
     * ! Public functions | Getters
     * ----------------------------------- */

    function getController() public view returns (address) {
        return address(this);
    }

    function getDao() public view returns (address) {
        return _dao;
    }

    function getMultisig() public view returns (address) {
        return _multisig;
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

    function getConverterLogic() public view returns (address) {
        return address(_converterLogic);
    }

    function getEnergyStorage() public view returns (address) {
        return address(_energyStorage);
    }

    function getLBAEnergyStorage() public view returns (address) {
        return address(_lbaEnergyStorage);
    }
}

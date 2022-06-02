// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Staking.sol";
import "./StakingStorage.sol";
import "./Converter.sol";
import "./ConverterStorage.sol";
import "./helpers/PermissionControl.sol";
import "./helpers/Util.sol";

// import "forge-std/console.sol";

/**
 * @dev ASM Genome Mining - Registry contract
 * @notice We use this contract to manage contracts addresses
 * @notice when we need to update some of them.
 */
contract Controller is Util, PermissionControl {
    Controller public controller_;
    Staking public stakingLogic_;
    StakingStorage public astoStorage_;
    StakingStorage public lpStorage_;
    Converter public converterLogic_;
    ConverterStorage public converterStorage_;
    IERC20 public astoToken_;
    IERC20 public lpToken_;

    address public manager; // DAO multisig contract, public for auto getter

    event ContractUpgraded(uint256 timestamp, string contractName, address oldAddress, address newAddress);

    constructor(address multisig) {
        if (!_isContract(multisig)) revert InvalidInput(INVALID_MULTISIG);
        manager = multisig;
        _setupRole(MANAGER_ROLE, multisig); // `RoleGranted` event will be emitted
    }

    function init(
        address astoToken,
        address astoStorage,
        address lpToken,
        address lpStorage,
        address stakingLogic,
        address converterLogic,
        address converterStorage
    ) public onlyRole(MANAGER_ROLE) {
        if (!_isContract(astoToken)) revert InvalidInput(INVALID_ASTO_CONTRACT);
        if (!_isContract(astoStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(lpToken)) revert InvalidInput(INVALID_LP_CONTRACT);
        if (!_isContract(lpStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(stakingLogic)) revert InvalidInput(INVALID_STAKING_LOGIC);
        if (!_isContract(converterLogic)) revert InvalidInput(INVALID_CONVERTER_LOGIC);
        if (!_isContract(converterStorage)) revert InvalidInput(INVALID_CONVERTER_STORAGE);

        // Saving addresses on init:
        astoToken_ = IERC20(astoToken);
        astoStorage_ = StakingStorage(astoStorage);
        lpToken_ = IERC20(lpToken);
        lpStorage_ = StakingStorage(lpStorage);
        stakingLogic_ = Staking(stakingLogic);
        converterLogic_ = Converter(converterLogic);
        converterStorage_ = ConverterStorage(converterStorage);

        // Initializing contracts
        _upgradeContracts(
            address(0), // we skip this step, as contracts already have the Controller role set
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            converterLogic,
            converterStorage
        );
    }

    /** ----------------------------------
     * ! Internal functions | Setters
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
        address converterStorage
    ) internal {
        if (_isContract(controller)) _setController(controller);
        if (_isContract(astoToken)) _setAstoToken(astoToken);
        if (_isContract(astoStorage)) _setAstoStorage(astoStorage);
        if (_isContract(lpToken)) _setLpToken(lpToken);
        if (_isContract(lpStorage)) _setLpStorage(lpStorage);
        if (_isContract(stakingLogic)) _setStakingLogic(stakingLogic);
        if (_isContract(converterLogic)) _setConverterLogic(converterLogic);
        if (_isContract(converterStorage)) _setConverterStorage(converterStorage);
    }

    function _setManager(address multisig) internal {
        manager = multisig;
        _updateRole(MANAGER_ROLE, multisig);
    }

    function _setController(address newContract) internal {
        stakingLogic_.setController(address(controller_));
        astoStorage_.setController(address(controller_));
        lpStorage_.setController(address(controller_));
        // converterLogic_.setController(address(controller_));
        // converterStorage_.setController(address(controller_));
        emit ContractUpgraded(block.timestamp, "Controller", address(this), newContract);
    }

    function _setStakingLogic(address newContract) internal {
        stakingLogic_ = Staking(newContract);
        stakingLogic_.init(
            address(manager),
            IERC20(astoToken_),
            address(astoStorage_),
            IERC20(lpToken_),
            address(lpStorage_)
        );
        emit ContractUpgraded(block.timestamp, "Staking Logic", address(this), newContract);
    }

    function _setAstoToken(address newContract) internal {
        astoToken_ = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "ASTO Token", address(this), newContract);
    }

    function _setAstoStorage(address newContract) internal {
        astoStorage_ = StakingStorage(newContract);
        astoStorage_.init(address(stakingLogic_));
        emit ContractUpgraded(block.timestamp, "ASTO Staking Storage", address(this), newContract);
    }

    function _setLpToken(address newContract) internal {
        lpToken_ = IERC20(newContract);
        emit ContractUpgraded(block.timestamp, "LP Token", address(this), newContract);
    }

    function _setLpStorage(address newContract) internal {
        lpStorage_ = StakingStorage(newContract);
        lpStorage_.init(address(stakingLogic_));
        emit ContractUpgraded(block.timestamp, "LP Staking Storage", address(this), newContract);
    }

    function _setConverterLogic(address newContract) internal {
        converterLogic_ = Converter(newContract);
        // converterLogic_.init(address(this), address(converterStorage_));
        emit ContractUpgraded(block.timestamp, "Converter Logic", address(this), newContract);
    }

    function _setConverterStorage(address newContract) internal {
        converterStorage_ = ConverterStorage(newContract);
        // converterStorage_.init(address(this), address(converterLogic_));
        emit ContractUpgraded(block.timestamp, "Converter Storage", address(this), newContract);
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
        address converterLogic,
        address converterStorage
    ) external onlyRole(MANAGER_ROLE) {
        _upgradeContracts(
            controller,
            astoToken,
            astoStorage,
            lpToken,
            lpStorage,
            stakingLogic,
            converterLogic,
            converterStorage
        );
    }

    function setManager(address multisig) external onlyRole(MANAGER_ROLE) {
        _setManager(multisig);
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

    function setConverterLogic(address newContract) external onlyRole(MANAGER_ROLE) {
        _setConverterLogic(newContract);
    }

    function setConverterStorage(address newContract) external onlyRole(MANAGER_ROLE) {
        _setConverterStorage(newContract);
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        stakingLogic_.pause();
        astoStorage_.pause();
        lpStorage_.pause();
        // converterLogicContract.pause();
        // converterStorageContract.pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        stakingLogic_.unpause();
        astoStorage_.unpause();
        lpStorage_.unpause();
        // converterLogicContract.unpause();
        // converterStorageContract.unpause();
    }

    /** ----------------------------------
     * ! Public functions | Getters
     * ----------------------------------- */

    function getController() public view returns (address) {
        return address(this);
    }

    function getManager() public view returns (address) {
        return manager;
    }

    function getStakingLogic() public view returns (address) {
        return address(stakingLogic_);
    }

    function getAstoStorage() public view returns (address) {
        return address(astoStorage_);
    }

    function getLpStorage() public view returns (address) {
        return address(lpStorage_);
    }

    function getConverterLogic() public view returns (address) {
        return address(converterLogic_);
    }

    function getConverterStorage() public view returns (address) {
        return address(converterStorage_);
    }
}

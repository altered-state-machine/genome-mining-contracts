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
contract Controller is Util, PermissionControl {
    Controller public controller_;
    Staking public stakingLogic_;
    StakingStorage public stakingStorage_;
    Converter public converterLogic_;
    ConverterStorage public converterStorage_;
    IERC20 public asto_;
    IERC20 public lp_;

    address public manager; // DAO multisig contract, public for auto getter

    event ContractUpgraded(uint256 timestamp, string contractName, address oldAddress, address newAddress);

    constructor(
        address multisig,
        address stakingLogic,
        address stakingStorage,
        address converterLogic,
        address converterStorage,
        address astoContract,
        address lpContract
    ) {
        if (!_isContract(multisig)) revert InvalidInput(INVALID_MULTISIG);
        if (!_isContract(stakingLogic)) revert InvalidInput(INVALID_STAKING_LOGIC);
        if (!_isContract(stakingStorage)) revert InvalidInput(INVALID_STAKING_STORAGE);
        if (!_isContract(converterLogic)) revert InvalidInput(INVALID_CONVERTER_LOGIC);
        if (!_isContract(converterStorage)) revert InvalidInput(INVALID_CONVERTER_STORAGE);
        if (!_isContract(astoContract)) revert InvalidInput(INVALID_ASTO_CONTRACT);
        if (!_isContract(lpContract)) revert InvalidInput(INVALID_LP_CONTRACT);

        manager = multisig;
        _setupRole(MANAGER_ROLE, multisig); // `RoleGranted` event will be emitted
        _upgradeContracts(address(this), stakingLogic, stakingStorage, converterLogic, converterStorage);
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
        address stakingLogic,
        address stakingStorage,
        address converterLogic,
        address converterStorage
    ) external onlyRole(MANAGER_ROLE) {
        _upgradeContracts(controller, stakingLogic, stakingStorage, converterLogic, converterStorage);
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

    function setStakingStorage(address newContract) external onlyRole(MANAGER_ROLE) {
        _setStakingStorage(newContract);
    }

    function setConverterLogic(address newContract) external onlyRole(MANAGER_ROLE) {
        _setConverterLogic(newContract);
    }

    function setConverterStorage(address newContract) external onlyRole(MANAGER_ROLE) {
        _setConverterStorage(newContract);
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        stakingLogic_.pause();
        stakingStorage_.pause();
        // converterLogicContract.pause();
        // converterStorageContract.pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        stakingLogic_.unpause();
        stakingStorage_.unpause();
        // converterLogicContract.unpause();
        // converterStorageContract.unpause();
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
        address stakingLogic,
        address stakingStorage,
        address converterLogic,
        address converterStorage
    ) internal {
        if (_isContract(controller)) _setController(controller);
        if (_isContract(stakingLogic)) _setStakingLogic(stakingLogic);
        if (_isContract(stakingStorage)) _setStakingStorage(stakingStorage);
        if (_isContract(converterLogic)) _setConverterLogic(converterLogic);
        if (_isContract(converterStorage)) _setConverterStorage(converterStorage);
    }

    function _setManager(address multisig) internal {
        manager = multisig;
        _updateRole(MANAGER_ROLE, multisig);
    }

    function _setController(address newContract) internal {
        // stakingLogic_.setController(address(controller_));
        // stakingStorage_.setController(address(controller_));
        // converterLogic_.setController(address(controller_));
        // converterStorage_.setController(address(controller_));

        emit ContractUpgraded(block.timestamp, "Controller", address(this), newContract);
    }

    function _setStakingLogic(address newContract) internal {
        stakingLogic_ = Staking(newContract);
        stakingLogic_.init(address(this), address(stakingStorage_), IERC20(asto_), IERC20(lp_));
        emit ContractUpgraded(block.timestamp, "Staking Logic", address(this), newContract);
    }

    function _setStakingStorage(address newContract) internal {
        stakingStorage_ = StakingStorage(newContract);
        stakingStorage_.init(address(this), address(stakingLogic_));
        emit ContractUpgraded(block.timestamp, "Staking Storage", address(this), newContract);
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

    function getStakingStorage() public view returns (address) {
        return address(stakingStorage_);
    }

    function getConverterLogic() public view returns (address) {
        return address(converterLogic_);
    }

    function getConverterStorage() public view returns (address) {
        return address(converterStorage_);
    }
}

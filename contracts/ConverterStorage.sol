// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ITime.sol";
import "./TimeConstants.sol";
import "./PermissionControl.sol";

// TODO import from utils
error WrongAddress(address addr, string errMsg);


/**
 * @dev ASM Genome Mining - Converter Storage contract
 */
contract ConverterStorage is ITime, TimeConstants, Pausable, Ownable, PermissionControl {
    constructor() {}

    function init(
        address _multisig,
        address _registry,
        address _converterLogic
    ) external onlyOwner {
        // TODO replace with utils
        if (address(_multisig) == address(0)) {
            revert WrongAddress(_multisig, "Wrong multisig address");
        }
        if (address(_registry) == address(0)) {
            revert WrongAddress(_multisig, "Wrong registry address");
        }
        if (address(_converterLogic == address(0))) {
            revert WrongAddress(_registry, "Wrong converter contract address");
        }

        _setupRole(REGISTRY_ROLE, _registry);
        _setupRole(MANAGER_ROLE, _converterLogic);
        _transferOwnership(_multisig);
    }
}

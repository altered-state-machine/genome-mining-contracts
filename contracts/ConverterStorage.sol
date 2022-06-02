// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./helpers/TimeConstants.sol";
import "./helpers/PermissionControl.sol";

// TODO import from utils
error InvalidInput(address addr, string errMsg);

/**
 * @dev ASM Genome Mining - Converter Storage contract
 */
contract ConverterStorage is TimeConstants, Pausable, Ownable, PermissionControl {
    constructor() {}

    function init(
        address _multisig,
        address _registry,
        address _converterLogic
    ) external onlyOwner {
        // TODO replace with utils
        if (address(_multisig) == address(0)) {
            revert InvalidInput(_multisig, "Wrong multisig address");
        }
        if (address(_registry) == address(0)) {
            revert InvalidInput(_multisig, "Wrong registry address");
        }
        if (address(_converterLogic) == address(0)) {
            revert InvalidInput(_registry, "Wrong converter contract address");
        }

        _setupRole(CONTROLLER_ROLE, _registry);
        _setupRole(MANAGER_ROLE, _converterLogic);
        _transferOwnership(_multisig);
    }
}

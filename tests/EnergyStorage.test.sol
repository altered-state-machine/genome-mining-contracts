// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../contracts/EnergyStorage.sol";
import "../contracts/Controller.sol";

import "ds-test/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM Genome Mining - Energy Storage contract
 */
contract EnergyStorageTestContract is DSTest, Util {
    EnergyStorage energyStorage_;
    Converter converterLogic_;

    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address deployer = address(this);
    address multisig = deployer; // for the testing we use deployer as a multisig

    function setUp() public {
        setupContracts();
        setupWallets();
    }

    function setupContracts() internal {
        controller_ = new Controller(multisig);
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings
    }
}

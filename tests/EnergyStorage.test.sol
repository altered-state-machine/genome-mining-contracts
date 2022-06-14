// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../contracts/EnergyStorage.sol";
import "../contracts/Controller.sol";
import "../contracts/Converter.sol";
import "../contracts/helpers/IConverter.sol";
import "../contracts/interfaces/ILiquidityBootstrapAuction.sol";

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM Genome Mining - Energy Storage contract
 */
contract EnergyStorageTestContract is DSTest, IConverter, Util {
    EnergyStorage energyStorage_;
    Converter converterLogic_;
    Controller controller_;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    ILiquidityBootstrapAuction lba = ILiquidityBootstrapAuction(0x6D08cF8E2dfDeC0Ca1b676425BcFCF1b0e064afA);
    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address deployer = address(this);
    address multisig = deployer; // for the testing we use deployer as a multisig

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    function setUp() public {
        setupContracts();
        setupWallets();
    }

    function setupContracts() internal {
        controller_ = new Controller(multisig);
        energyStorage_ = new EnergyStorage(address(controller_));
        converterLogic_ = new Converter(address(controller_), address(lba), new Period[](0));

        vm.startPrank(address(controller_));
        energyStorage_.init(address(converterLogic_));
        vm.stopPrank();
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings
    }

    /** ----------------------------------
     * ! Logic
     * ----------------------------------- */

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND: wallet address is valid
     * @notice  THEN: should get correct consumed amount from mappings
     */
    function testIncreaseConsumedAmount() public skip(false) {
        assert(energyStorage_.consumedAmount(someone) == 0);

        uint256 newConsumedAmount = 100;
        vm.startPrank(address(converterLogic_));
        energyStorage_.increaseConsumedAmount(someone, newConsumedAmount);
        assert(energyStorage_.consumedAmount(someone) == newConsumedAmount);
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND:  wallet address is invalid
     * @notice  THEN: should revert the message WRONG_ADDRESS
     */
    function testIncreaseConsumedAmount_wrong_wallet() public skip(false) {
        vm.startPrank(address(converterLogic_));
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_ADDRESS));
        energyStorage_.increaseConsumedAmount(address(0), 100);
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is not a converter
     * @notice  THEN: should revert the message "AccessControl: account ..."
     */
    function testIncreaseConsumedAmount_not_a_converter() public skip(false) {
        vm.startPrank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0x9d56108290ea0bc9c5c59c3ad357dca9d1b29ed7f3ae1443bef2fa2159bdf5e8"
        );
        energyStorage_.increaseConsumedAmount(someone, 100);
    }

    /** ----------------------------------
     * ! Contract modifiers
     * ----------------------------------- */

    /**
     * @notice this modifier will skip the test
     */
    modifier skip(bool isSkipped) {
        if (!isSkipped) {
            _;
        }
    }

    /**
     * @notice this modifier will skip the testFail*** tests ONLY
     */
    modifier skipFailing(bool isSkipped) {
        if (isSkipped) {
            require(0 == 1);
        } else {
            _;
        }
    }
}

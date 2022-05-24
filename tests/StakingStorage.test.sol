// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma solidity >=0.5.16;

import "../contracts/StakingStorageTestHelper.sol";
import "../contracts/StakingStorage.sol";
import "./../contracts/ITime.sol";

import "ds-test/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM LP Time contract
 */
contract StakingStorageTestContract is DSTest, ITime {
    StakingStorageTestHelper tc;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    address someoneAddress = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address ownerAddress = 0xeb24a849E6C908D4166D34D7E3133B452CB627D2;
    // Mainnet: 0x2E3B1351F37C8E5a97706297302E287A93ff4986
    // Rinkeby: tbd
    IERC20 token = IERC20(0x2E3B1351F37C8E5a97706297302E287A93ff4986);

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        tc = new StakingStorageTestHelper(address(ownerAddress), token);

        setupContract(); // general
        setupWallets(); // balances
        setupStates(); // staking
    }

    function setupContract() internal {
        // ...
        vm.prank(ownerAddress);
        tc.unpause();
    }

    function setupWallets() internal {
        vm.deal(address(tc), 1000); // adds 1000 ETH to the contract balance
        vm.deal(ownerAddress, 1); // gas spendings
        vm.deal(someoneAddress, 1); // gas spendings
        // TODO: mint ASTO to the `ownerAddress` and `someoneAddress`
    }

    function setupStates() internal {
        uint256[] memory _stake = new uint256[](1);
        _stake[0] = uint256(1);

        // Stake something
        vm.prank(someoneAddress);

        // Do something else
        // ...
    }

    /** ----------------------------------
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @notice GIVEN:
     * @notice  WHEN:
     * @notice   AND:
     * @notice  THEN:
     */
    function testWithdraw() public skip(true) {
        assert(0 != 1);
    }

    /** ----------------------------------
     * ! Test contract modifiers
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
    modifier skipExpectedToFail(bool isSkipped) {
        if (isSkipped) {
            require(0 == 1);
        } else {
            _;
        }
    }
}

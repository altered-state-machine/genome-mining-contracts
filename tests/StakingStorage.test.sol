// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
// pragma solidity >=0.5.16;

import "../contracts/TestHelpers/StakingStorageTestHelper.sol";
import "../contracts/Registry.sol";
import "../contracts/Staking.sol";
import "../contracts/StakingStorage.sol";
import "../contracts/helpers/IStaking.sol";
import "../contracts/helpers/Tokens.sol";
// import "../contracts/Converter.sol";
// import "../contracts/ConverterStorage.sol";

import "ds-test/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM Genome Mining - Staking contract
 */
contract StakingStorageTestContract is DSTest, IStaking, Tokens {
    StakingStorageTestHelper t_; // Staking Storage - contract under test
    Staking manager_;
    Registry registry_;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address deployer = address(this);
    address multisig = 0xeb24a849E6C908D4166D34D7E3133B452CB627D2;

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        setupContracts();
        topupWallets();
    }

    function setupContracts() internal {
        t_ = new StakingStorageTestHelper(multisig);
        // console.log("owner:", t_.owner(), " | this contract:", address(this));
        manager_ = new Staking(multisig);
        registry_ = new Registry(
            address(multisig),
            address(manager_),
            address(this),
            someone,
            someone
        );
        t_.init(address(registry_), address(manager_));
    }

    function topupWallets() internal {
        // vm.deal(address(c_ut), 10);
        // vm.deal(address(manager), 10);
        // vm.deal(address(registry), 10);
        // vm.deal(address(someone), 10);
        // vm.deal(address(deployer), 10);
        // vm.deal(address(multisig), 10);
    }

    /** ----------------------------------
     * ! Logic
     * ----------------------------------- */

    /**
     * @notice GIVEN: Known token, a wallet, and amount
     * @notice  WHEN: caller is not a manager
     * @notice   AND: amount is not greater than a balance
     * @notice  THEN: should return stakeID
     */
    function testUpdateHistory() public skip(false) {
        uint256 stakeId;
        vm.startPrank(address(manager_));
        stakeId = t_.updateHistory(Token.ASTO, deployer, 1);
        assert(stakeId == 1);
        stakeId = t_.updateHistory(Token.ASTO, deployer, 1);
        assert(stakeId == 2);
    }

    /**
     * @notice GIVEN: Unknow token, a correct wallet, and correct amount
     * @notice  WHEN: caller is a manager
     * @notice   AND: amount is not greater than a balance
     * @notice  THEN: should revert with message "" // TODO add message
     */
    function testFailUpdateHistory_wrong_token() public skipFailing(false) {
        vm.prank(address(manager_));
        t_.updateHistory(Token(uint8(5)), deployer, 1); // enum has 3 entries (0-2)
    }

    /**
     * @notice GIVEN: Unknow token, a correct wallet, and missed amount
     * @notice  WHEN: caller is a manager
     * @notice   AND: amount is not greater than a balance
     * @notice  THEN: should revert with message "" // TODO add message
     */
    function testFailUpdateHistory_wrong_amount() public skipFailing(false) {
        vm.prank(address(manager_));
        t_.updateHistory(Token.ASTO, deployer, 0);
    }

    /**
     * @notice GIVEN: Known token, a wallet, and amount
     * @notice  WHEN: caller is a manager
     * @notice   AND: amount is greater than a balance
     * @notice  THEN: should revert with message "" // TODO add message
     */
    function testFailUpdateHistory_insufficient_balance()
        public
        skipFailing(true)
    {
        vm.prank(address(manager_));
        t_.updateHistory(Token.ASTO, deployer, 1000e18);
    }

    /**
     * @notice GIVEN: Known token, and amount, but wrong/missed wallet
     * @notice  WHEN: caller is a manager
     * @notice   AND: amount is not greater than a balance
     * @notice  THEN: should revert with message "" // TODO add message
     */
    function testFailUpdateHistory_wrong_wallet() public skipFailing(false) {
        vm.prank(address(manager_));
        t_.updateHistory(Token.ASTO, address(0), 1);
    }

    /**
     * @notice GIVEN: all correct params
     * @notice  WHEN: caller is not a manager
     * @notice  THEN: should revert with message "" // TODO add message
     */
    function testFailUpdateHistory_not_a_manager() public skipFailing(false) {
        t_.updateHistory(Token.ASTO, deployer, 10);
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

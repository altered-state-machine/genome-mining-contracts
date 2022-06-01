// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../contracts/TestHelpers/StakingStorageTestHelper.sol";
import "../contracts/mocks/MockedERC20.sol";
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
contract StakingStorageTestContract is DSTest, IStaking, Util {
    StakingStorageTestHelper storage_; // Staking Storage - contract under test
    Staking staker_;
    Registry registry_;
    Tokens tokens_;
    IERC20 asto_;
    IERC20 lp_;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    uint256 amount = 1_234_567_890_000_000_000; // 1.23456789 ASTO
    uint256 initialBalance = 100e18;
    uint256 userBalance = 10e18;
    uint256 astoToken = 1; // tokenId

    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address deployer = address(this);
    address multisig = deployer; // for the testing we use deployer as a multisig

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        deployContracts(); // instantiate GM contracts
        setupTokens(); // mock tokens
        initContracts(); // instantiate GM contracts
        setupWallets(); // topup balances for testing
    }

    function deployContracts() internal {
        storage_ = new StakingStorageTestHelper();
        staker_ = new Staking();
        registry_ = new Registry(
            address(multisig), // Multisig - Registry checks if the address is a contract, so we fake it
            address(staker_), // Staker - the real one
            address(storage_), // StakingStorage - the real one
            address(staker_), // Converter - Registry checks if the address is a contract, so we fake it
            address(staker_) // ConverterStorage - Registry checks if the address is a contract, so we fake it
        );
    }

    function setupTokens() internal {
        IERC20 asto = IERC20(new MockedERC20("ASTO Token", "ASTO", address(staker_), initialBalance));
        IERC20 lp = IERC20(new MockedERC20("Uniswap LP Token", "LP", address(staker_), initialBalance));
        tokens_ = new Tokens(asto, lp);
        // asto_ = tokens_.tokens(1);
        // lp_ = tokens_.tokens(2);
    }

    function initContracts() internal {
        staker_.init(multisig, address(registry_), address(storage_), tokens_);
        storage_.init(multisig, address(registry_), address(staker_));
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings

        // asto_.mint(someone, userBalance);
        // lp_.mint(someone, userBalance);
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
        vm.startPrank(address(staker_));
        stakeId = storage_.updateHistory(astoToken, deployer, 1);
        assert(stakeId == 1);
        stakeId = storage_.updateHistory(astoToken, deployer, 1);
        assert(stakeId == 2);
    }

    /**
     * @notice GIVEN: Unknow token, a correct wallet, and correct amount
     * @notice  WHEN: caller is a manager
     * @notice   AND: amount is not greater than a balance
     * @notice  THEN: should revert
     *
     * @dev Can't properly test it as an error happens here,
     * @dev rather than in the contract under test,
     * @dev because of the non-existing conversion (such token doesn't exist)
     * @dev that's why test called `testFailWithdraw_...` and
     * @dev a non-specific error is expected.
     * @dev Please double check implementation to be sure,
     * @dev that wrong token is caught and a proper error is returned.
     */
    function testFailUpdateHistory_wrong_token() public skipFailing(false) {
        vm.prank(address(staker_));
        storage_.updateHistory(uint256(5), deployer, 1); // enum has 3 entries (0-2)
    }

    /**
     * @notice GIVEN: Unknow token, a correct wallet, and missed amount
     * @notice  WHEN: caller is a manager
     * @notice   AND: amount is not greater than a balance
     * @notice  THEN: should revert with message WRONG_AMOUNT
     */
    function testUpdateHistory_wrong_amount() public skipFailing(false) {
        vm.prank(address(staker_));
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_AMOUNT));
        storage_.updateHistory(astoToken, deployer, 0);
    }

    /**
     * @notice GIVEN: Known token, and amount, but wrong/missed wallet
     * @notice  WHEN: caller is a manager
     * @notice   AND: amount is not greater than a balance
     * @notice  THEN: should revert with message WRONG_ADDRESS
     */
    function testUpdateHistory_wrong_wallet() public skipFailing(false) {
        vm.prank(address(staker_));
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_ADDRESS));
        storage_.updateHistory(astoToken, address(0), 1);
    }

    /**
     * @notice GIVEN: all correct params
     * @notice  WHEN: caller is not a manager
     * @notice  THEN: should revert with message "" // TODO add message
     */
    function testUpdateHistory_not_a_staker() public skipFailing(false) {
        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xb9e206fa2af7ee1331b72ce58b6d938ac810ce9b5cdb65d35ab723fd67badf9e"
        );
        storage_.updateHistory(astoToken, deployer, 10);
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

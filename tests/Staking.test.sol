// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../contracts/TestHelpers/StakingTestHelper.sol";
import "../contracts/Staking.sol";
import "../contracts/StakingStorage.sol";
import "../contracts/helpers/IStaking.sol";
import "../contracts/helpers/Tokens.sol";
import "../contracts/mocks/MockedERC20.sol";

import "ds-test/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM ASTO Time contract
 */
contract StakingTestContract is DSTest, IStaking, Util {
    StakingTestHelper staker_;
    StakingStorage storage_;
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
        setupTokens(); // mock tokens
        setupContracts(); // instantiate GM contracts
        setupWallets(); // topup balances for testing
    }

    function setupTokens() internal {
        IERC20 asto = IERC20(new MockedERC20("ASTO Token", "ASTO", address(staker_), initialBalance));
        IERC20 lp = IERC20(new MockedERC20("Uniswap LP Token", "LP", address(staker_), initialBalance));
        tokens_ = new Tokens(asto, lp);
        asto_ = tokens_.tokens(1);
        lp_ = tokens_.tokens(2);
    }

    function setupContracts() internal {
        staker_ = new StakingTestHelper();
        storage_ = new StakingStorage();
        registry_ = new Registry(
            address(multisig), // Multisig - Registry checks if the address is a contract, so we fake it
            address(staker_), // Staker - the real one
            address(storage_), // StakingStorage - the real one
            address(staker_), // Converter - Registry checks if the address is a contract, so we fake it
            address(staker_) // ConverterStorage - Registry checks if the address is a contract, so we fake it
        );
        tokens_.init(address(multisig), address(registry_));
        staker_.init(multisig, address(registry_), address(storage_), tokens_);
        storage_.init(multisig, address(registry_), address(staker_));
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings

        // contractOf[asto].mint(address(staker_), initialBalance);
        // asto_.mint(someone, userBalance);
        // lp_.mint(someone, userBalance);
    }

    /** ----------------------------------
     * ! Only owner functions
     * ----------------------------------- */

    /**
     * @notice GIVEN: owner of this contract calls this function
     * @notice  WHEN: there are some tokens on the balance of this contract
     * @notice   AND: token, address and amount are specified
     * @notice  THEN: specified amount of specified tokens is transferred to the specified address
     */
    function testWithdraw_happy_path() public skip(false) {
        console.log(address(multisig), address(staker_), address(storage_), address(registry_));
        uint256 balanceBefore = asto_.balanceOf(address(staker_));
        assert(
            keccak256("MANAGER_ROLE") == bytes32(0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08)
        ); // true
        // assert(
        //     keccak256("REGISTRY_ROLE") == bytes32(0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08)
        // );
        vm.startPrank(address(multisig));
        registry_.pause();
        staker_.withdraw(astoToken, deployer, amount);
        console.log("withdrawn");
        uint256 balanceAfter = asto_.balanceOf(address(this));
        assert(balanceBefore - balanceAfter == amount);
    }

    /**
     * @notice GIVEN: NOT an owner of this contract calls this function
     * @notice  WHEN: there are some tokens on the balance of this contract
     * @notice   AND: token, address and amount are specified
     * @notice  THEN: specified amount of specified tokens is transferred to the specified address
     */
    function testWithdraw_not_an_owner() public skip(false) {
        vm.prank(multisig);
        staker_.pause();
        vm.prank(someone);
        // 0xa847d497b38b9e11833eac3ea03921b40e6d847c - someone
        // 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08 - MANAGER_ROLE
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08"
        );
        staker_.withdraw(astoToken, deployer, amount);
    }

    /**
     * @notice GIVEN: an owner of this contract calls this function
     * @notice  WHEN: requested amount is greater than a balance
     * @notice   AND: token, address and amount are specified
     * @notice  THEN: reverts with message "insuffucient balance"
     */
    function testWithdraw_insufficient_balance() public skip(true) {
        uint256 balanceBefore = asto_.balanceOf(address(staker_));
        vm.startPrank(multisig);
        registry_.pause();
        vm.expectRevert(abi.encodeWithSelector(Util.InvalidInput.selector, INSUFFICIENT_BALANCE));
        staker_.withdraw(astoToken, deployer, balanceBefore + amount);
    }

    /**
     * @notice GIVEN: an owner of this contract calls this function
     * @notice  WHEN: there are some tokens on the balance of this contract
     * @notice   AND: wrong token is specified
     * @notice  THEN: reverts with wrong token message
     *
     * @dev Can't properly test it as an error happens here,
     * @dev rather than in the contract under test,
     * @dev because of the non-existing conversion (such token doesn't exist)
     * @dev that's why test called `testFailWithdraw_...` and
     * @dev a non-specific error is expected.
     * @dev Please double check implementation to be sure,
     * @dev that wrong token is caught and a proper error is returned.
     */
    function testFailWithdraw_wrong_token() public skipFailing(false) {
        uint256 balanceBefore = asto_.balanceOf(address(staker_));
        require(balanceBefore > 0, "Topup balance to continue testing");
        vm.prank(someone);
        staker_.withdraw(uint256(5), deployer, amount);
    }

    /**
     * @notice GIVEN: an owner of this contract calls this function
     * @notice  WHEN: there are some tokens on the balance of this contract
     * @notice   AND: address is missed
     * @notice  THEN: reverts with wrong address message
     */
    function testWithdraw_no_address() public skip(true) {
        uint256 balanceBefore = asto_.balanceOf(address(staker_));
        require(balanceBefore > 0, "Topup balance to continue testing");
        vm.startPrank(multisig);
        registry_.pause();
        vm.expectRevert(abi.encodeWithSelector(Util.InvalidInput.selector, WRONG_ADDRESS));
        staker_.withdraw(astoToken, address(0), amount);
    }

    /**
     * @notice GIVEN: an owner of this contract calls this function
     * @notice  WHEN: the contract is NOT paused
     * @notice  THEN: reverts with "Pausable: not paused" message
     */
    function testWithdraw_not_paused() public skip(false) {
        uint256 balanceBefore = asto_.balanceOf(address(staker_));
        require(balanceBefore > 0, "Topup balance to continue testing");
        vm.expectRevert("Pausable: not paused");
        vm.startPrank(multisig);
        staker_.withdraw(astoToken, address(0), amount);
    }

    /** ----------------------------------
     * ! Busines logic
     * ----------------------------------- */

    /**
     * @notice GIVEN: token, amount
     * @notice  WHEN: user calls `stake()` function
     * @notice   AND: token is registered
     * @notice   AND: amount is not greater than user's balance
     * @notice  THEN: transfer that amount to the contract
     * @notice   AND: update stake history of the user
     */
    function testStake_happy_path() public skip(true) {
        uint256 logicBalanceBefore = asto_.balanceOf(address(staker_));
        uint256 userBalanceBefore = asto_.balanceOf(someone);

        vm.startPrank(someone);
        staker_.stake(astoToken, amount);

        console.log("----");

        uint256 logicBalanceAfter = asto_.balanceOf(address(staker_));
        uint256 userBalanceAfter = asto_.balanceOf(someone);
        uint256 counter = storage_.getTotalStakesCounter();
        uint256 lastStakeId = storage_.getUserLastStakeId(someone);
        uint256 userLastStakeId = storage_.getUserLastStakeId(someone);
        Stake memory newStake = storage_.getStake(someone, userLastStakeId);

        assertEq(lastStakeId, userLastStakeId);
        assertEq(counter, 1);
        assertEq(logicBalanceBefore, initialBalance); // after initial topup (see setup section)
        assertEq(logicBalanceAfter, logicBalanceBefore + amount);
        assertEq(userBalanceBefore, userBalance);
        assertEq(userBalanceAfter, userBalanceBefore - amount);
        assertEq(newStake.amount, amount);
    }

    /**
     * @notice GIVEN: token, amount
     * @notice  WHEN: user calls `stake()` function
     * @notice   AND: token is registered
     * @notice   AND: amount is greater than user's balance
     * @notice  THEN: revert with message "Insufficient balance"
     */
    function testStake_insufficient_balance() public skip(true) {
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, INSUFFICIENT_BALANCE));
        vm.prank(someone);
        staker_.stake(astoToken, userBalance + amount);
    }

    /**
     * @notice GIVEN: token, amount
     * @notice  WHEN: user calls `stake()` function
     * @notice   AND: token is registered
     * @notice   AND: amount was not specified (equal to 0)
     * @notice  THEN: revert with message WRONG_AMOUNT
     */
    function testStake_zero_amount() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_AMOUNT));
        vm.prank(someone);
        staker_.stake(astoToken, 0);
    }

    /**
     * @notice GIVEN: stake exists
     * @notice  WHEN: stake owner calls the `unStake()`
     * @notice   AND: specifies correct amount (less than a balance) and token
     * @notice  THEN: storage history updated and tokens transfered to user
     */
    function testUnStake_happy_path() public skip(true) {
        vm.startPrank(someone);
        staker_.stake(astoToken, amount);

        uint256 logicBalanceBefore = asto_.balanceOf(address(staker_));
        uint256 userBalanceBefore = asto_.balanceOf(someone);

        staker_.unStake(astoToken, amount);

        uint256 logicBalanceAfter = asto_.balanceOf(address(staker_));
        uint256 userBalanceAfter = asto_.balanceOf(someone);
        uint256 counter = storage_.getTotalStakesCounter();
        uint256 lastStakeId = storage_.getUserLastStakeId(someone);
        uint256 userLastStakeId = storage_.getUserLastStakeId(someone);
        Stake memory newStake = storage_.getStake(someone, userLastStakeId);

        assertEq(lastStakeId, userLastStakeId);
        assertEq(counter, 1);
        assertEq(logicBalanceBefore, initialBalance); // after initial topup (see setup section)
        assertEq(logicBalanceAfter, logicBalanceBefore - amount);
        assertEq(userBalanceBefore, userBalance);
        assertEq(userBalanceAfter, userBalanceBefore + amount);
        assertEq(newStake.amount, amount);
    }

    /**
     * @notice GIVEN: user want to unstake some amount
     * @notice  WHEN: user's current stake is less than that amount
     * @notice  THEN: should revert with INSUFFICIENT_BALANCE message
     */
    function testUnStake_insufficient_balance() public skip(true) {
        vm.startPrank(someone);
        staker_.stake(astoToken, amount);
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, INSUFFICIENT_BALANCE));
        staker_.unStake(astoToken, userBalance + amount + 1);
    }

    /**
     * @notice GIVEN: user has no staking history
     * @notice  WHEN: calls `unstake()`
     * @notice  THEN: reverts with error NoStakes
     */
    function testUnStake_no_existing_history() public skip(true) {
        vm.startPrank(someone);
        staker_.stake(astoToken, amount);
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, NO_STAKES));
        staker_.unStake(astoToken, 1);
    }

    /**
     * @notice GIVEN: token, amount
     * @notice  WHEN: user calls `unStake()` function
     * @notice   AND: token is registered
     * @notice   AND: amount was not specified (equal to 0)
     * @notice  THEN: revert with message WRONG_AMOUNT
     */
    function testUnStake_zero_amount() public skip(true) {
        vm.expectRevert(abi.encodeWithSelector(Util.InvalidInput.selector, WRONG_AMOUNT));
        vm.prank(someone);
        staker_.unStake(astoToken, 0);
    }

    /**
     * @notice GIVEN: token
     * @notice  WHEN: anyone calls this function
     * @notice  THEN: return how much tokens are locked
     */
    function testGetTotalValueLocked() public skip(true) {
        uint256 res = staker_.getTotalValueLocked(astoToken);
        assert(res == 0);
        staker_.stake(astoToken, 1);
        res = staker_.getTotalValueLocked(astoToken);
        console.log(res);
        assert(res == 1);
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
    modifier skipFailing(bool isSkipped) {
        if (isSkipped) {
            require(0 == 1);
        } else {
            _;
        }
    }
}

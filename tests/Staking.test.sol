// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../contracts/Staking.sol";
import "../contracts/Staking.sol";
import "../contracts/Controller.sol";
import "../contracts/StakingStorage.sol";
import "../contracts/helpers/IStaking.sol";

import "../contracts/mocks/MockedERC20.sol";

import "ds-test/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM ASTO Time contract
 */
contract StakingTestContract is DSTest, IStaking, Util {
    Staking staker_;
    StakingStorage astoStorage_;
    StakingStorage lpStorage_;
    Controller controller_;
    MockedERC20 astoToken_;
    MockedERC20 lpToken_;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    uint256 amount = 1_234_567_890_000_000_000; // 1.23456789 ASTO
    uint256 initialBalance = 100e18;
    uint256 userBalance = 10e18;
    uint256 astoToken = 0; // tokenId

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
        astoToken_ = new MockedERC20("ASTO Token", "ASTO", deployer, initialBalance);
        lpToken_ = new MockedERC20("Uniswap LP Token", "LP", deployer, initialBalance);
    }

    function setupContracts() internal {
        controller_ = new Controller(multisig);

        staker_ = new Staking(address(controller_));
        astoStorage_ = new StakingStorage(address(controller_));
        lpStorage_ = new StakingStorage(address(controller_));

        controller_.init(
            address(astoToken_),
            address(astoStorage_),
            address(lpToken_),
            address(lpStorage_),
            address(staker_),
            address(staker_), // we don't test it here, so we fake it
            address(staker_) // we don't test it here, so we fake it
        );
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        astoToken_.mint(address(staker_), userBalance);
        astoToken_.mint(someone, userBalance);
    }

    /** ----------------------------------
     * ! Admin functions
     * ----------------------------------- */

    function test_beforeAll() public view skip(true) {
        console.log("Multisig", address(multisig));
        console.log("Deployer", address(deployer));
        console.log("Controller", address(controller_));
        console.log("Staker", address(staker_));
        console.log("ASTO Token", address(astoToken_));
        console.log("LP Token", address(lpToken_));
        console.log("ASTO Storage", address(astoStorage_));
        console.log("LP Storage", address(lpStorage_));
    }

    /**
     * @notice GIVEN: owner of this contract calls this function
     * @notice  WHEN: there are some tokens on the balance of this contract
     * @notice   AND: token, address and amount are specified
     * @notice  THEN: specified amount of specified tokens is transferred to the specified address
     */
    function testWithdraw_happy_path() public skip(false) {
        vm.prank(address(multisig));
        uint256 balanceBefore = astoToken_.balanceOf(address(staker_));
        controller_.pause();
        vm.prank(address(multisig));
        staker_.withdraw(astoToken, deployer, amount);
        uint256 balanceAfter = astoToken_.balanceOf(address(staker_));
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
        controller_.pause();
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
    function testWithdraw_insufficient_balance() public skip(false) {
        uint256 balanceBefore = astoToken_.balanceOf(address(staker_));
        vm.startPrank(multisig);
        controller_.pause();
        vm.expectRevert(abi.encodeWithSelector(Util.InvalidInput.selector, INSUFFICIENT_BALANCE));
        staker_.withdraw(astoToken, deployer, balanceBefore + amount);
    }

    /**
     * @notice GIVEN: an owner of this contract calls this function
     * @notice  WHEN: there are some tokens on the balance of this contract
     * @notice   AND: wrong token is specified
     * @notice  THEN: reverts with wrong token message
     */
    function testWithdraw_wrong_token() public skip(false) {
        vm.startPrank(address(multisig));
        controller_.pause();
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_TOKEN));
        staker_.withdraw(uint256(5), deployer, amount);
    }

    /**
     * @notice GIVEN: an owner of this contract calls this function
     * @notice  WHEN: there are some tokens on the balance of this contract
     * @notice   AND: address is missed
     * @notice  THEN: reverts with wrong address message
     */
    function testWithdraw_no_recipient() public skip(false) {
        vm.startPrank(multisig);
        controller_.pause();
        vm.expectRevert(abi.encodeWithSelector(Util.InvalidInput.selector, WRONG_ADDRESS));
        staker_.withdraw(astoToken, address(0), amount);
    }

    /**
     * @notice GIVEN: an owner of this contract calls this function
     * @notice  WHEN: the contract is NOT paused
     * @notice  THEN: reverts with "Pausable: not paused" message
     */
    function testWithdraw_not_paused() public skip(false) {
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
    function testStake_happy_path() public skip(false) {
        uint256 logicBalanceBefore = astoToken_.balanceOf(address(staker_));
        uint256 userBalanceBefore = astoToken_.balanceOf(someone);

        vm.startPrank(someone);

        astoToken_.approve(address(staker_), amount); // this one initiated by UI
        staker_.stake(astoToken, amount);

        uint256 logicBalanceAfter = astoToken_.balanceOf(address(staker_));
        uint256 userBalanceAfter = astoToken_.balanceOf(someone);
        uint256 lastStakeId = astoStorage_.getUserLastStakeId(someone);
        uint256 userLastStakeId = astoStorage_.getUserLastStakeId(someone);
        Stake memory newStake = astoStorage_.getStake(someone, userLastStakeId);

        assertEq(lastStakeId, userLastStakeId, "lastStakeId == userLastStakeId");
        assertEq(logicBalanceAfter, logicBalanceBefore + amount, "logicBalanceAfter == logicBalanceBefore + amount");
        assertEq(userBalanceBefore, userBalance, "userBalanceBefore == userBalance");
        assertEq(userBalanceAfter, userBalanceBefore - amount, "userBalanceAfter == userBalanceBefore - amount");
        assertEq(newStake.amount, amount, "newStake.amount == amount");
    }

    /**
     * @notice GIVEN: token, amount
     * @notice  WHEN: user calls `stake()` function
     * @notice   AND: token is registered
     * @notice   AND: amount is greater than user's balance
     * @notice  THEN: revert with message "Insufficient balance"
     */
    function testStake_insufficient_balance() public skip(false) {
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
     * @notice  WHEN: stake owner calls the `unstake()`
     * @notice   AND: specifies correct amount (less than a balance) and token
     * @notice  THEN: storage history updated and tokens transfered to user
     */
    function testUnstake_happy_path() public skip(false) {
        vm.startPrank(someone);
        astoToken_.approve(address(staker_), amount); // this one initiated by UI
        staker_.stake(astoToken, amount);
        uint256 logicBalanceBefore = astoToken_.balanceOf(address(staker_));
        uint256 userBalanceBefore = astoToken_.balanceOf(someone);

        uint256 userLastStakeId = astoStorage_.getUserLastStakeId(someone);
        Stake memory beforeUnstakeBalance = astoStorage_.getStake(someone, userLastStakeId);

        staker_.unstake(astoToken, amount);

        uint256 logicBalanceAfter = astoToken_.balanceOf(address(staker_));
        uint256 userBalanceAfter = astoToken_.balanceOf(someone);

        userLastStakeId = astoStorage_.getUserLastStakeId(someone);
        Stake memory afterUnstakeBalance = astoStorage_.getStake(someone, userLastStakeId);

        // contract and user ASTO balances checks
        assertEq(logicBalanceAfter, logicBalanceBefore - amount, "Contract balance decreased");
        assertEq(userBalanceBefore, userBalance - amount, "User balance should be decresed after stake");
        assertEq(userBalanceAfter, userBalance, "User balance should be restored after unstake");
        assertEq(userBalanceAfter, userBalanceBefore + amount, "User balance = balance before unstake + amount");
        // user STAKE balance check
        assertEq(
            afterUnstakeBalance.amount,
            beforeUnstakeBalance.amount - amount,
            "User's stake balance should be decreased by amount"
        );
        assertEq(afterUnstakeBalance.amount, 0, "User's stake balance should be 0");
    }

    /**
     * @notice GIVEN: user want to unstake some amount
     * @notice  WHEN: user's current stake is less than that amount
     * @notice  THEN: should revert with INSUFFICIENT_BALANCE message
     */
    function testUnstake_insufficient_balance() public skip(false) {
        vm.startPrank(someone);
        astoToken_.approve(address(staker_), amount); // this one initiated by UI
        staker_.stake(astoToken, amount);
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, INSUFFICIENT_BALANCE));
        staker_.unstake(astoToken, userBalance + amount + 1);
    }

    /**
     * @notice GIVEN: user has no staking history
     * @notice  WHEN: calls `unstake()`
     * @notice  THEN: reverts with error NoStakes
     */
    function testUnstake_no_existing_history() public skip(false) {
        vm.startPrank(someone);
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, NO_STAKES));
        staker_.unstake(astoToken, 1);
    }

    /**
     * @notice GIVEN: token, amount
     * @notice  WHEN: user calls `unstake()` function
     * @notice   AND: token is registered
     * @notice   AND: amount was not specified (equal to 0)
     * @notice  THEN: revert with message WRONG_AMOUNT
     */
    function testUnstake_zero_amount() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(Util.InvalidInput.selector, WRONG_AMOUNT));
        vm.prank(someone);
        staker_.unstake(astoToken, 0);
    }

    /**
     * @notice GIVEN: token
     * @notice  WHEN: anyone calls this function
     * @notice  THEN: return how much tokens are locked
     */
    function testGetTotalValueLocked() public skip(false) {
        uint256 res = staker_.getTotalValueLocked(astoToken);
        assert(res == 0);
        vm.startPrank(someone);
        astoToken_.approve(address(staker_), amount); // this one initiated by UI
        staker_.stake(astoToken, 1);
        res = staker_.getTotalValueLocked(astoToken);
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

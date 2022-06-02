// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../contracts/StakingStorage.sol";
import "../contracts/mocks/MockedERC20.sol";
import "../contracts/Controller.sol";
import "../contracts/Staking.sol";
import "../contracts/StakingStorage.sol";
import "../contracts/helpers/IStaking.sol";

// import "../contracts/Converter.sol";
// import "../contracts/ConverterStorage.sol";

import "ds-test/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM Genome Mining - Staking contract
 */
contract StakingStorageTestContract is DSTest, IStaking, Util {
    StakingStorage astoStorage_;
    StakingStorage lpStorage_;
    Staking staker_;
    Controller controller_;
    MockedERC20 astoToken_;
    MockedERC20 lpToken_;

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
        astoToken_ = new MockedERC20("ASTO Token", "ASTO", deployer, initialBalance);
        lpToken_ = new MockedERC20("Uniswap LP Token", "LP", deployer, initialBalance);
    }

    function setupContracts() internal {
        controller_ = new Controller(multisig);
        astoStorage_ = new StakingStorage(address(controller_));
        lpStorage_ = new StakingStorage(address(controller_));
        staker_ = new Staking(address(controller_));
        controller_.init(
            address(staker_), // Staker - the real one
            address(astoToken_),
            address(astoStorage_), // StakingStorage - the real one
            address(lpToken_),
            address(lpStorage_), // StakingStorage - the real one
            address(staker_), // Converter - Controller checks if the address is a contract, so we fake it
            address(staker_) // ConverterStorage - Controller checks if the address is a contract, so we fake it
        );
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings
        astoToken_.mint(someone, userBalance);
        lpToken_.mint(someone, userBalance);
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
        stakeId = astoStorage_.updateHistory(deployer, 1);
        assert(stakeId == 1);
        stakeId = astoStorage_.updateHistory(deployer, 1);
        assert(stakeId == 2);
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
        astoStorage_.updateHistory(address(0), 1);
    }

    /**
     * @notice GIVEN: all correct params
     * @notice  WHEN: caller is not a manager
     * @notice  THEN: should revert with message "AccessControl: account ..."
     */
    function testUpdateHistory_not_a_staker() public skipFailing(false) {
        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xb9e206fa2af7ee1331b72ce58b6d938ac810ce9b5cdb65d35ab723fd67badf9e"
        );
        astoStorage_.updateHistory(deployer, 10);
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

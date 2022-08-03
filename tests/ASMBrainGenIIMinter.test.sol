// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../contracts/Converter.sol";
import "../contracts/EnergyStorage.sol";
import "../contracts/Controller.sol";
import "../contracts/Staking.sol";
import "../contracts/mocks/MockedERC20.sol";
import "../contracts/helpers/IStaking.sol";
import "../contracts/interfaces/ILiquidityBootstrapAuction.sol";
import "../contracts/interfaces/IASMBrainGenIIMinter.sol";

import "../contracts/ASMBrainGenII.sol";
import "../contracts/ASMBrainGenIIMinter.sol";
import "../contracts/helpers/Util.sol";
import "../contracts/helpers/IConverter.sol";

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

bytes32 constant hash1 = 0x4c1d3f8d288ffb699fd8863dcfb17a95a1ab634698c33b1f12e0e745e0cfd082;
string constant tokenURI1 = "ipfs://QmTTmZYNUuwBXz1584A954NrcHdQ4zdf3eziRtjZLqicUq";

bytes32 constant hash2 = 0xb057493760d27be9cf33d7aa9406f2fa638128806739f1e7f559d87707913b0e;
string constant tokenURI2 = "ipfs://QmaD1fGGA8UEF5gFrrkZEGzMGmtJ3XMtzgMTx7SPQy22Dj";

bytes32 constant hash3 = 0x8a1c9eeb5ce404f74cdd230993aa21c19bd1b5012ca7615e48ef2a4dad270b96;
string constant tokenURI3 = "ipfs://QmXdnHSGgRU4dUUmbe32UEfiPSZFFZGXFycapBhezfwKBT";

bytes32 constant r = 0xb9a4d477e1dc81aa33f61e5da22a0bc18b246a104433de192b62db0160ee9d1a;
bytes32 constant s = 0x5506b312bd3fb43e16a5b47e8355247923fe6ba0104e8ccf9a5f6ceb5b52f943;
uint8 constant v = 27;
bytes constant signature = abi.encodePacked(r, s, v);

/**
 * @dev Tests for the ASM Genome Mining - ASM Brain GenII Minter contract
 */
contract ASMBrainGenIIMinterTestContract is DSTest, IASMBrainGenIIMinter, IConverter, Util {
    EnergyStorage energyStorage_;
    EnergyStorage lbaEnergyStorage_;
    Controller controller_;
    Staking stakingLogic_;
    StakingStorage astoStorage_;
    StakingStorage lpStorage_;
    MockedERC20 astoToken_;
    MockedERC20 lpToken_;

    Converter converter;
    ASMBrainGenII brain;
    ASMBrainGenIIMinter minter;

    uint256 initialBalance = 100e18;
    uint256 cycle1StartTime = block.timestamp;
    uint256 cycle1EndTime = block.timestamp + 60 days;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    ILiquidityBootstrapAuction lba = ILiquidityBootstrapAuction(0x25720f1f60bd2F50C50841fF04d658da10BDf0B7); // goerli
    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address signer = 0xaebC048B4D219D6822C17F1fe06E36Eba67D4144;
    address deployer = address(this);
    address multisig = deployer; // for the testing we use deployer as a multisig
    address dao = deployer; // for the testing we use deployer as a dao

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        setupTokens(); // mock tokens
        setupContracts();
        setupWallets();
    }

    function setupContracts() internal {
        // TODO update multiplier
        Period[] memory p = new Period[](1);
        p[0] = Period(uint128(cycle1StartTime), uint128(cycle1EndTime), 1, 1, 1);
        controller_ = new Controller(multisig);
        astoStorage_ = new StakingStorage(address(controller_));
        lpStorage_ = new StakingStorage(address(controller_));
        energyStorage_ = new EnergyStorage(address(controller_));
        lbaEnergyStorage_ = new EnergyStorage(address(controller_));
        stakingLogic_ = new Staking(address(controller_));
        converter = new Converter(address(controller_), address(lba), p, 0);

        controller_.init(
            address(dao),
            address(astoToken_),
            address(astoStorage_),
            address(lpToken_),
            address(lpStorage_),
            address(stakingLogic_),
            address(converter),
            address(energyStorage_),
            address(lbaEnergyStorage_)
        );
        controller_.unpause();

        brain = new ASMBrainGenII(multisig);
        minter = new ASMBrainGenIIMinter(signer, multisig, address(converter), address(brain));

        vm.prank(multisig);
        brain.addMinter(address(minter));

        ASMBrainGenIIMinter.PeriodConfig memory config = ASMBrainGenIIMinter.PeriodConfig(
            cycle1EndTime,
            cycle1EndTime + 60 days,
            100,
            35000,
            30
        );
        vm.prank(multisig);
        minter.updateConfiguration(1, config);
    }

    function setupTokens() internal {
        astoToken_ = new MockedERC20("ASTO Token", "ASTO", deployer, initialBalance, 18);
        lpToken_ = new MockedERC20("Uniswap LP Token", "LP", deployer, initialBalance, 18);
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings
    }

    function testMint() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime);
        minter.mint(hashes, signature, 1);

        assertEq(brain.balanceOf(someone), 3, "balance didn't match");
        assertEq(brain.numberMinted(someone), 3, "numberMinted didn't match");
        assertEq(brain.tokenHash(0), hash1, "tokenHash didn't match");
        assertEq(brain.tokenURI(0), tokenURI1, "tokenURI didn't match");
    }

    function testMintWithInvalidRemainingSupply() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        vm.mockCall(address(brain), abi.encodeWithSelector(brain.totalSupply.selector), abi.encode(34999));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime);
        vm.expectRevert(abi.encodeWithSelector(InsufficientSupply.selector, 3, 1));
        minter.mint(hashes, signature, 1);
    }

    function testMintWithEmptyHashes() public skip(false) {
        bytes32[] memory hashes = new bytes32[](0);

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime);
        vm.expectRevert(abi.encodeWithSelector(InvalidHashes.selector, 0, 30, 1));
        minter.mint(hashes, signature, 1);
    }

    function testMintWithTooManyHashes() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        ASMBrainGenIIMinter.PeriodConfig memory config = ASMBrainGenIIMinter.PeriodConfig(
            cycle1EndTime,
            cycle1EndTime + 60 days,
            100,
            35000,
            2
        );
        vm.prank(multisig);
        minter.updateConfiguration(1, config);

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime);
        vm.expectRevert(abi.encodeWithSelector(InvalidHashes.selector, 3, 2, 1));
        minter.mint(hashes, signature, 1);
    }

    function testMintBeforePeriodStarts() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime - 1 days);
        vm.expectRevert(abi.encodeWithSelector(NotStarted.selector));
        minter.mint(hashes, signature, 1);
    }

    function testMintAfterPeriodEnds() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime + 61 days);
        vm.expectRevert(abi.encodeWithSelector(AlreadyFinished.selector));
        minter.mint(hashes, signature, 1);
    }

    function testMintWithInvalidPeriodId() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        ASMBrainGenIIMinter.PeriodConfig memory config = ASMBrainGenIIMinter.PeriodConfig(
            cycle1EndTime + 60 days,
            cycle1EndTime + 120 days,
            100,
            35000,
            30
        );
        vm.prank(multisig);
        minter.updateConfiguration(2, config);

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime + 60 days);
        vm.expectRevert(abi.encodeWithSelector(InvalidPeriod.selector, 2, 2));
        minter.mint(hashes, signature, 2);
    }

    function testMintWithInvalidSignature() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash2;

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime);
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));
        minter.mint(hashes, signature, 1);
    }

    function testMintWithUsedSignature() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime);
        minter.mint(hashes, signature, 1);
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));
        minter.mint(hashes, signature, 1);
    }

    function testMintWithInsufficientEnergy() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(200));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.startPrank(someone);
        vm.warp(cycle1EndTime);
        vm.expectRevert(abi.encodeWithSelector(InsufficientEnergy.selector, 300, 200));
        minter.mint(hashes, signature, 1);
    }

    function testRemainingSupplyWithNoBrainsMinted() public skip(false) {
        vm.mockCall(address(brain), abi.encodeWithSelector(brain.totalSupply.selector), abi.encode(0));

        uint256 remainingSupply = minter.remainingSupply(1);
        assertEq(remainingSupply, 35000, "remainingSupply didn't match");
    }

    function testRemainingSupplyWithBrainsMinted() public skip(false) {
        uint256 brainsMinted = 5500;
        vm.mockCall(address(brain), abi.encodeWithSelector(brain.totalSupply.selector), abi.encode(brainsMinted));

        uint256 remainingSupply = minter.remainingSupply(1);
        assertEq(remainingSupply, 35000 - brainsMinted, "remainingSupply didn't match");
    }

    function testRemainingSupplyWithAllBrainsMinted() public skip(false) {
        uint256 brainsMinted = 35000;
        vm.mockCall(address(brain), abi.encodeWithSelector(brain.totalSupply.selector), abi.encode(brainsMinted));

        uint256 remainingSupply = minter.remainingSupply(1);
        assertEq(remainingSupply, 0, "remainingSupply didn't match");
    }

    function testRemainingSupplyWithInvalidPeriod() public skip(false) {
        vm.mockCall(address(brain), abi.encodeWithSelector(brain.totalSupply.selector), abi.encode(100));

        uint256 remainingSupply = minter.remainingSupply(2);
        assertEq(remainingSupply, 0, "remainingSupply didn't match");
    }

    function testUpdateConverter() public skip(false) {
        vm.prank(multisig);
        minter.updateConverter(someone);
        assertEq(address(minter.energyConverter()), someone, "converter didn't match");
    }

    function testUpdateConverterWithInvalidAccount() public skip(false) {
        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        minter.updateConverter(someone);
    }

    function testUpdateBrain() public skip(false) {
        vm.prank(multisig);
        minter.updateBrain(someone);
        assertEq(address(minter.brain()), someone, "brain didn't match");
    }

    function testUpdateBrainWithInvalidAccount() public skip(false) {
        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        minter.updateConverter(someone);
    }

    function testUpdateSigner() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getCurrentPeriodId.selector), abi.encode(2));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.getEnergy.selector), abi.encode(300));
        vm.mockCall(address(converter), abi.encodeWithSelector(converter.useEnergy.selector), "");

        vm.prank(multisig);
        minter.updateSigner(someone);

        vm.startPrank(someone);
        vm.warp(cycle1EndTime);
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));
        minter.mint(hashes, signature, 1);
    }

    function testUpdateSignerWithInvalidAccount() public skip(false) {
        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        minter.updateSigner(someone);
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

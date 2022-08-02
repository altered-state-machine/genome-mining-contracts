// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../contracts/ASMBrainGenII.sol";
import "../contracts/helpers/Util.sol";

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

bytes32 constant hash1 = 0x4c1d3f8d288ffb699fd8863dcfb17a95a1ab634698c33b1f12e0e745e0cfd082;
string constant tokenURI1 = "ipfs://QmTTmZYNUuwBXz1584A954NrcHdQ4zdf3eziRtjZLqicUq";

bytes32 constant hash2 = 0xb057493760d27be9cf33d7aa9406f2fa638128806739f1e7f559d87707913b0e;
string constant tokenURI2 = "ipfs://QmaD1fGGA8UEF5gFrrkZEGzMGmtJ3XMtzgMTx7SPQy22Dj";

bytes32 constant hash3 = 0x8a1c9eeb5ce404f74cdd230993aa21c19bd1b5012ca7615e48ef2a4dad270b96;
string constant tokenURI3 = "ipfs://QmXdnHSGgRU4dUUmbe32UEfiPSZFFZGXFycapBhezfwKBT";

/**
 * @dev Tests for the ASM Genome Mining - Energy Converter contract
 */
contract ASMBrainGenIITestContract is DSTest, Util {
    ASMBrainGenII brain;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

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
        setupContracts();
        setupWallets();
    }

    function setupContracts() internal {
        brain = new ASMBrainGenII(multisig);
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings

        vm.prank(multisig);
        brain.addMinter(multisig);
    }

    function testMintWithValidMinter() public skip(false) {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = hash1;
        hashes[1] = hash2;
        hashes[2] = hash3;

        vm.prank(multisig);
        brain.mint(someone, hashes);

        assertEq(brain.balanceOf(someone), 3, "balance didn't match");
        assertEq(brain.numberMinted(someone), 3, "numberMinted didn't match");
        assertEq(brain.tokenHash(0), hash1, "tokenHash didn't match");
        assertEq(brain.tokenURI(0), tokenURI1, "tokenURI didn't match");
    }

    function testMintWithInvalidMinter() public skip(false) {
        bytes32[] memory hashes = new bytes32[](1);
        hashes[0] = hash1;

        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"
        );
        brain.mint(someone, hashes);
    }

    function testTokenURIWithInvalidTokenID() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, TOKEN_NOT_EXIST));
        brain.tokenURI(0);
    }

    function testUpdateBaseURI() public skip(false) {
        string memory newBaseURI = "https://test.com/meta/";
        vm.prank(multisig);
        brain.updateBaseURI(newBaseURI);

        assertEq(brain.baseURI(), newBaseURI, "baseURI didn't match");
    }

    function testUpdateBaseURIWithInvalidAccount() public skip(false) {
        string memory newBaseURI = "https://test.com/meta/";
        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        brain.updateBaseURI(newBaseURI);
    }

    function testAddMinter() public skip(false) {
        vm.prank(multisig);
        brain.addMinter(someone);

        bool hasRole = brain.hasRole(MINTER_ROLE, someone);
        assert(hasRole == true);
    }

    function testAddMinterByInvalidAccount() public skip(false) {
        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        brain.addMinter(someone);
    }

    function testAddMinterWithInvalidAccount() public skip(false) {
        vm.prank(multisig);
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, INVALID_MINTER));
        brain.addMinter(address(0));
    }

    function testRemoveMinter() public skip(false) {
        vm.startPrank(multisig);
        brain.addMinter(someone);
        brain.removeMinter(someone);

        bool hasRole = brain.hasRole(MINTER_ROLE, someone);
        assert(hasRole == false);
    }

    function testRemoveMinterByInvalidAccount() public skip(false) {
        vm.prank(multisig);
        brain.addMinter(someone);

        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        brain.removeMinter(someone);
    }

    function testRemoveMinterWithInvalidAccount() public skip(false) {
        vm.prank(multisig);
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, INVALID_MINTER));
        brain.removeMinter(someone);
    }

    function testAddAdmin() public skip(false) {
        vm.prank(multisig);
        brain.addAdmin(someone);

        bool hasRole = brain.hasRole(ADMIN_ROLE, someone);
        assert(hasRole == true);
    }

    function testAddAdminByInvalidAccount() public skip(false) {
        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        brain.addAdmin(someone);
    }

    function testAddAdminWithInvalidAccount() public skip(false) {
        vm.prank(multisig);
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, INVALID_ADMIN));
        brain.addAdmin(address(0));
    }

    function testRemoveAdmin() public skip(false) {
        vm.startPrank(multisig);
        brain.addAdmin(someone);
        brain.removeAdmin(someone);

        bool hasRole = brain.hasRole(ADMIN_ROLE, someone);
        assert(hasRole == false);
    }

    function testRemoveAdminByInvalidAccount() public skip(false) {
        vm.prank(someone);
        vm.expectRevert(
            "AccessControl: account 0xa847d497b38b9e11833eac3ea03921b40e6d847c is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        brain.removeAdmin(someone);
    }

    function testRemoveAdminWithInvalidAccount() public skip(false) {
        vm.prank(multisig);
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, INVALID_ADMIN));
        brain.removeAdmin(someone);
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

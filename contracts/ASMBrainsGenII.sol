// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/IPFS.sol";
import "./helpers/Util.sol";

bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

contract ASMBrainGenII is Util, AccessControl, IPFS, ERC721AQueryable {
    string public baseURI = "ipfs://";

    mapping(uint256 => bytes32) public tokenHash;

    event Minted(address indexed recipient, uint256 tokenId, bytes32 hash);
    event BaseURIUpdated(address indexed operator, string newbaseURI);

    constructor(address multisig) ERC721A("ASMBrainGenII", "ASMBrainGenII") {
        _grantRole(ADMIN_ROLE, multisig);
    }

    /**
     * @notice Mint Gen II Brains to `recipient` with the IPFS hashes
     * @dev This function can only be called from contracts or wallets with MINTER_ROLE
     * @param recipient The wallet address used for minting
     * @param hashes A list of IPFS Multihash digests. Each Gen II Brain should have an unique token hash
     */
    function mint(address recipient, bytes32[] calldata hashes) external onlyRole(MINTER_ROLE) {
        uint256 nextTokenId = _nextTokenId();
        uint256 quantity = hashes.length;

        for (uint256 i = 0; i < quantity; ++i) {
            tokenHash[i + nextTokenId] = hashes[i];
            emit Minted(recipient, i + nextTokenId, hashes[i]);
        }

        _mint(recipient, quantity);
    }

    /**
     * @notice Get tokenURI for Brain `tokenId`
     * @dev The IPFS Multihash digest stored in tokenHash is converted to IPFS CIDv0
     * @param `tokenId` The token ID
     * @return The tokenURL as a string
     */
    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert InvalidInput(TOKEN_NOT_EXIST);
        bytes32 hash = tokenHash[tokenId];
        return string(abi.encodePacked(_baseURI(), cidv0(hash)));
    }

    /**
     * @notice Get baseURI which will be used in tokenURI
     * @dev This is an internal function that can only be used inside the contract
     * @return The baseURI as a string
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Update baseURI to `_newBaseURI`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _newBaseURI The new baseURI to update
     */
    function updateBaseURI(string calldata _newBaseURI) external onlyRole(ADMIN_ROLE) {
        baseURI = _newBaseURI;
        emit BaseURIUpdated(msg.sender, _newBaseURI);
    }

    /**
     * @notice Add a new minter address (contract or wallet)
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _newMinter The new minted address to be added
     */
    function addMinter(address _newMinter) external onlyRole(ADMIN_ROLE) {
        if (_newMinter == address(0)) revert InvalidInput(INVALID_MINTER);
        _grantRole(MINTER_ROLE, _newMinter);
    }

    /**
     * @notice Remove an existing minter
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _minter The minter address to be removed
     */
    function removeMinter(address _minter) external onlyRole(ADMIN_ROLE) {
        if (!hasRole(MINTER_ROLE, _minter)) revert InvalidInput(INVALID_MINTER);
        _revokeRole(MINTER_ROLE, _minter);
    }

    /**
     * @notice Add admin address (contract or wallet)
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _newAdmin The new admin address to be granted
     */
    function addAdmin(address _newAdmin) external onlyRole(ADMIN_ROLE) {
        if (_newAdmin == address(0)) revert InvalidInput(INVALID_ADMIN);
        _grantRole(ADMIN_ROLE, _newAdmin);
    }

    /**
     * @notice Remove admin address
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _admin The new admin address to be removed
     */
    function removeAdmin(address _admin) external onlyRole(ADMIN_ROLE) {
        if (!hasRole(ADMIN_ROLE, _admin)) revert InvalidInput(INVALID_ADMIN);
        _revokeRole(ADMIN_ROLE, _admin);
    }

    /**
     * @notice Get the total minted count for `owner`
     * @param owner The wallet address
     * @return The total minted count
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, IERC721A, ERC721A)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/IPFS.sol";

contract ASMBrainGenII is AccessControl, IPFS, ERC721AQueryable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public baseURI = "ipfs://";

    mapping(uint256 => bytes32) public tokenHash;

    event Minted(address indexed recipient, uint256 tokenId, bytes32 hash);

    constructor(address multisig) ERC721A("ASMBrainGenII", "ASMBrainGenII") {
        // TODO validate multisig
        _grantRole(ADMIN_ROLE, multisig);
    }

    function mint(address recipient, bytes32[] calldata hashes) external onlyRole(MINTER_ROLE) {
        uint256 nextTokenId = _nextTokenId();
        uint256 quantity = hashes.length;

        for (uint256 i = 0; i < quantity; ++i) {
            tokenHash[i + nextTokenId] = hashes[i];
            emit Minted(recipient, i + nextTokenId, hashes[i]);
        }

        _mint(recipient, quantity);
    }

    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        bytes32 hash = tokenHash[tokenId];
        return string(abi.encodePacked(_baseURI(), cidv0(hash)));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string calldata _newBaseURI) external onlyRole(ADMIN_ROLE) {
        baseURI = _newBaseURI;
        // TODO event
    }

    function updateMinter(address _oldMinter, address _newMinter) external onlyRole(ADMIN_ROLE) {
        if (_oldMinter != address(0)) {
            _revokeRole(MINTER_ROLE, _oldMinter);
        }

        if (_newMinter != address(0)) {
            _grantRole(MINTER_ROLE, _newMinter);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC721A, ERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}

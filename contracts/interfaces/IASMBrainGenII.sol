// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/extensions/IERC721AQueryable.sol";

interface IASMBrainGenII is IERC721AQueryable {
    function mint(address recipient, bytes32[] calldata hashes) external;

    event Minted(address indexed recipient, uint256 tokenId, bytes32 hash);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "openzeppelin/token/ERC721/ERC721.sol";

contract MockNft is ERC721("MockNft", "mnft") {
    function safeMint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }
}

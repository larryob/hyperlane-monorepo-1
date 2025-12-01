// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IHypERC721URIStorage {
    // ============ Functions ============
    function tokenURI(
        uint256 tokenId
    )
        external
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory);
    function supportsInterface(
        bytes4 interfaceId
    )
        external
        view
        override(ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable)
        returns (bool);
}

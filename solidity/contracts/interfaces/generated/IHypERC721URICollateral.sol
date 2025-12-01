// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface IHypERC721URICollateral {
    // ============ Functions ============
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _tokenId
    ) external payable override returns (bytes32 messageId);
}

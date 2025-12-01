// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IHypERC721Collateral {
    // ============ Functions ============
    function initialize(
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) external initializer;
    function token() external view override returns (address);
    function feeRecipient() external view override returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IHypERC721 {
    // ============ Functions ============
    function initialize(
        uint256 _mintAmount,
        string memory _name,
        string memory _symbol,
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) external initializer;
    function token() external view override returns (address);
    function feeRecipient() external view override returns (address);
}

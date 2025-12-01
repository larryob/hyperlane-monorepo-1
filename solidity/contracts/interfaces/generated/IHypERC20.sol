// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {Quote} from "../interfaces/ITokenBridge.sol";

interface IHypERC20 {
    // ============ Functions ============
    function initialize(
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol,
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) external initializer;
    function decimals() external view override returns (uint8);
    function token() external view override returns (address);
}

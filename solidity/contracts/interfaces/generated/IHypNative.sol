// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {Quote, ITokenBridge} from "../interfaces/ITokenBridge.sol";

interface IHypNative {
    // ============ Functions ============
    function initialize(
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) external initializer;
    function deposit(
        address receiver
    ) external payable returns (uint256 shares);
    function token() external pure override returns (address);
}

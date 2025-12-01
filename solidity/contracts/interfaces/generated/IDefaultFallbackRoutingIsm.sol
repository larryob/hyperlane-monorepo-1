// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";

interface IDefaultFallbackRoutingIsm {
    // ============ Functions ============
    function module(
        uint32 origin
    ) external view override returns (IInterchainSecurityModule);
}

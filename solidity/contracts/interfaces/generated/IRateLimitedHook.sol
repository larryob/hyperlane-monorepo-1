// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IPostDispatchHook} from "../../interfaces/hooks/IPostDispatchHook.sol";

interface IRateLimitedHook {
    // ============ Functions ============
    function hookType() external pure returns (uint8);
}

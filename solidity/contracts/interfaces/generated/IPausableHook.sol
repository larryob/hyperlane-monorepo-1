// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IPostDispatchHook} from "../interfaces/hooks/IPostDispatchHook.sol";

interface IPausableHook {
    // ============ Functions ============
    function pause() external;
    function unpause() external;
    function hookType() external pure override returns (uint8);
}

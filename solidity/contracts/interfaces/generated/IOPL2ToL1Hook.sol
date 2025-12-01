// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IPostDispatchHook} from "../interfaces/hooks/IPostDispatchHook.sol";
import {ICrossDomainMessenger} from "../interfaces/optimism/ICrossDomainMessenger.sol";

interface IOPL2ToL1Hook {
    // ============ Functions ============
    function hookType() external pure override returns (uint8);
}

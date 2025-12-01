// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IPostDispatchHook} from "../../interfaces/hooks/IPostDispatchHook.sol";

interface IDomainRoutingHook {
    // ============ Functions ============
    function hookType() external pure virtual returns (uint8);
    function setHook(uint32 _destination, address _hook) external;
    function setHooks(HookConfig[] calldata configs) external;
    function supportsMetadata(
        bytes calldata
    ) external pure override returns (bool);
}

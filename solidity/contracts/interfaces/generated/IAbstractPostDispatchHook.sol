// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IPostDispatchHook} from "../../interfaces/hooks/IPostDispatchHook.sol";

interface IAbstractPostDispatchHook {
    // ============ Functions ============
    function supportsMetadata(
        bytes calldata metadata
    ) external pure virtual returns (bool);
    function postDispatch(
        bytes calldata metadata,
        bytes calldata message
    ) external payable override;
    function quoteDispatch(
        bytes calldata metadata,
        bytes calldata message
    ) external view override returns (uint256);
}

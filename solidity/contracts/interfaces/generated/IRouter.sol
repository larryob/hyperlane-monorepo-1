// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IMessageRecipient} from "../interfaces/IMessageRecipient.sol";
import {IPostDispatchHook} from "../interfaces/hooks/IPostDispatchHook.sol";

interface IRouter {
    // ============ Functions ============
    function domains() external view returns (uint32[] memory);
    function routers(uint32 _domain) external view virtual returns (bytes32);
    function unenrollRemoteRouter(uint32 _domain) external virtual;
    function enrollRemoteRouter(
        uint32 _domain,
        bytes32 _router
    ) external virtual;
    function enrollRemoteRouters(
        uint32[] calldata _domains,
        bytes32[] calldata _addresses
    ) external virtual;
    function unenrollRemoteRouters(uint32[] calldata _domains) external virtual;
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable virtual override onlyMailbox;
}

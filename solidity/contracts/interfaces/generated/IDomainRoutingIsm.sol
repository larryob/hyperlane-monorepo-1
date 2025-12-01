// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";

interface IDomainRoutingIsm {
    // ============ Functions ============
    function initialize(address _owner) external initializer;
    function initialize(
        address _owner,
        uint32[] calldata _domains,
        IInterchainSecurityModule[] calldata __modules
    ) external initializer;
    function set(uint32 _domain, IInterchainSecurityModule _module) external;
    function remove(uint32 _domain) external;
    function domains() external view returns (uint256[] memory);
    function module(
        uint32 origin
    ) external view virtual returns (IInterchainSecurityModule);
    function route(
        bytes calldata _message
    ) external view override returns (IInterchainSecurityModule);
}

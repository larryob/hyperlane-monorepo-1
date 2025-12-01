// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";

interface IAbstractDomainRoutingIsmFactory {
    // ============ Events ============
    event ModuleDeployed(DomainRoutingIsm module);

    // ============ Functions ============
    function deploy(
        address _owner,
        uint32[] calldata _domains,
        IInterchainSecurityModule[] calldata _modules
    ) external returns (DomainRoutingIsm);
    function implementation() external view virtual returns (address);
    function implementation() external view override returns (address);
}

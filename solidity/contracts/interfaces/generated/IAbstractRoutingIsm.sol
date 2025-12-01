// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";
import {IRoutingIsm} from "../../interfaces/isms/IRoutingIsm.sol";

interface IAbstractRoutingIsm {
    // ============ Functions ============
    function route(
        bytes calldata _message
    ) external view virtual returns (IInterchainSecurityModule);
    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external returns (bool);
}

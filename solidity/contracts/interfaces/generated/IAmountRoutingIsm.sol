// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";

interface IAmountRoutingIsm {
    // ============ Functions ============
    function route(
        bytes calldata _message
    ) external view override returns (IInterchainSecurityModule);
}

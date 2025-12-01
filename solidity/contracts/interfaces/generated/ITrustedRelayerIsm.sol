// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../interfaces/IInterchainSecurityModule.sol";

interface ITrustedRelayerIsm {
    // ============ Functions ============
    function verify(
        bytes calldata,
        bytes calldata message
    ) external view returns (bool);
}

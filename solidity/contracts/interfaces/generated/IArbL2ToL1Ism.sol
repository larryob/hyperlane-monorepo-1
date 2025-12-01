// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";
import {IBridge} from "@arbitrum/nitro-contracts/src/bridge/IBridge.sol";
import {IOutbox} from "@arbitrum/nitro-contracts/src/bridge/IOutbox.sol";

interface IArbL2ToL1Ism {
    // ============ Functions ============
    function verify(
        bytes calldata metadata,
        bytes calldata message
    ) external override returns (bool);
}

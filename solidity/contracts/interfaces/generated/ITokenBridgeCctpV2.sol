// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IMessageHandlerV2} from "../interfaces/cctp/IMessageHandlerV2.sol";
import {ITokenMessengerV2} from "../interfaces/cctp/ITokenMessengerV2.sol";
import {IMessageTransmitterV2} from "../interfaces/cctp/IMessageTransmitterV2.sol";

interface ITokenBridgeCctpV2 {
    // ============ Errors ============
    error MaxFeeTooHigh();

    // ============ Functions ============
    function handleReceiveFinalizedMessage(
        uint32 sourceDomain,
        bytes32 sender,
        uint32 /*finalityThresholdExecuted*/,
        bytes calldata messageBody
    ) external override returns (bool);
    function handleReceiveUnfinalizedMessage(
        uint32 sourceDomain,
        bytes32 sender,
        uint32 /*finalityThresholdExecuted*/,
        bytes calldata messageBody
    ) external override returns (bool);
}

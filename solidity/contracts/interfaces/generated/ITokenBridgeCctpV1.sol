// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IMessageHandler} from "../interfaces/cctp/IMessageHandler.sol";
import {ITokenMessengerV1} from "../interfaces/cctp/ITokenMessenger.sol";
import {IMessageTransmitter} from "../interfaces/cctp/IMessageTransmitter.sol";

interface ITokenBridgeCctpV1 {
    // ============ Functions ============
    function handleReceiveMessage(
        uint32 sourceDomain,
        bytes32 sender,
        bytes calldata body
    ) external override returns (bool);
}

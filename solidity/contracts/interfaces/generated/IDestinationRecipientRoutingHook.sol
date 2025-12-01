// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IPostDispatchHook} from "../../interfaces/hooks/IPostDispatchHook.sol";

interface IDestinationRecipientRoutingHook {
    // ============ Functions ============
    function configCustomHook(
        uint32 destinationDomain,
        bytes32 recipient,
        address hook
    ) external;
}

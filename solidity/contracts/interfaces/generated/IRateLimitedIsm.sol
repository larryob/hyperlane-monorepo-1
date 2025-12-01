// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";

interface IRateLimitedIsm {
    // ============ Functions ============
    function moduleType() external pure returns (uint8);
    function verify(
        bytes calldata,
        bytes calldata _message
    )
        external
        onlyRecipient(_message)
        validateMessageOnce(_message)
        returns (bool);
}

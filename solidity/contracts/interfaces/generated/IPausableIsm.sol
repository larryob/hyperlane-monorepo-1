// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../interfaces/IInterchainSecurityModule.sol";

interface IPausableIsm {
    // ============ Functions ============
    function verify(
        bytes calldata,
        bytes calldata
    ) external view whenNotPaused returns (bool);
    function pause() external;
    function unpause() external;
}

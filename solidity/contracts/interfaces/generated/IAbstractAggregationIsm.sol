// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";
import {IAggregationIsm} from "../../interfaces/isms/IAggregationIsm.sol";

interface IAbstractAggregationIsm {
    // ============ Functions ============
    function modulesAndThreshold(
        bytes calldata _message
    ) external view virtual returns (address[] memory, uint8);
    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external returns (bool);
}

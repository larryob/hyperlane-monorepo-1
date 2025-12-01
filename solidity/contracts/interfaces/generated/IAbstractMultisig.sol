// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IMultisigIsm} from "../../interfaces/isms/IMultisigIsm.sol";

interface IAbstractMultisig {
    // ============ Functions ============
    function signatureCount(
        bytes calldata _metadata
    ) external pure virtual returns (uint256);
    function validatorsAndThreshold(
        bytes calldata _message
    ) external view virtual returns (address[] memory, uint8);
    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external view returns (bool);
}

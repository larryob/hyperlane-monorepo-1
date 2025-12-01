// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";
import {IStaticWeightedMultisigIsm} from "../../interfaces/isms/IWeightedMultisigIsm.sol";

interface IAbstractStaticWeightedMultisigIsm {
    // ============ Functions ============
    function validatorsAndThresholdWeight(
        bytes calldata /* _message*/
    ) external view virtual returns (ValidatorInfo[] memory, uint96);
    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external view virtual returns (bool);
}

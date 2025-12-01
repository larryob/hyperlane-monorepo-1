// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IStaticWeightedMultisigIsm} from "../interfaces/isms/IWeightedMultisigIsm.sol";

interface IStaticWeightedValidatorSetFactory {
    // ============ Functions ============
    function deploy(
        IStaticWeightedMultisigIsm.ValidatorInfo[] calldata _validators,
        uint96 _thresholdWeight
    ) external returns (address);
    function getAddress(
        IStaticWeightedMultisigIsm.ValidatorInfo[] calldata _validators,
        uint96 _thresholdWeight
    ) external view returns (address);
}

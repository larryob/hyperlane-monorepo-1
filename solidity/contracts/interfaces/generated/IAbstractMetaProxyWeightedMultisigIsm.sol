// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";

interface IAbstractMetaProxyWeightedMultisigIsm {
    // ============ Functions ============
    function validatorsAndThresholdWeight(
        bytes calldata /* _message*/
    ) external pure override returns (ValidatorInfo[] memory, uint96);
}

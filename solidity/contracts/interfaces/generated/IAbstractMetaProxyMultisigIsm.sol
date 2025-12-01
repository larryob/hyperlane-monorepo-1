// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";

interface IAbstractMetaProxyMultisigIsm {
    // ============ Functions ============
    function validatorsAndThreshold(
        bytes calldata
    ) external pure override returns (address[] memory, uint8);
}

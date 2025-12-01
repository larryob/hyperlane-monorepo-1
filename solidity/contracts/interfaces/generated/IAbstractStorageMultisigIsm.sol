// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";
import {IThresholdAddressFactory} from "../../interfaces/IThresholdAddressFactory.sol";

interface IAbstractStorageMultisigIsm {
    // ============ Events ============
    event ValidatorsAndThresholdSet(address[] validators, uint8 threshold);
    event ModuleDeployed(address module);

    // ============ Functions ============
    function initialize(
        address _owner,
        address[] memory _validators,
        uint8 _threshold
    ) external initializer;
    function setValidatorsAndThreshold(
        address[] memory _validators,
        uint8 _threshold
    ) external;
    function validatorsAndThreshold(
        bytes calldata /* _message */
    ) external view override returns (address[] memory, uint8);
    function deploy(
        address[] calldata _validators,
        uint8 _threshold
    ) external returns (address ism);
    function implementation() external view virtual returns (address);
    function implementation() external view override returns (address);
    function implementation() external view override returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IThresholdAddressFactory} from "../../interfaces/IThresholdAddressFactory.sol";

interface IStorageAggregationIsm {
    // ============ Events ============
    event ModulesAndThresholdSet(address[] modules, uint8 threshold);
    event ModuleDeployed(address module);

    // ============ Functions ============
    function initialize(
        address _owner,
        address[] memory _modules,
        uint8 _threshold
    ) external initializer;
    function setModulesAndThreshold(
        address[] memory _modules,
        uint8 _threshold
    ) external;
    function modulesAndThreshold(
        bytes calldata /* _message */
    ) external view override returns (address[] memory, uint8);
    function deploy(
        address[] calldata _modules,
        uint8 _threshold
    ) external returns (address ism);
}

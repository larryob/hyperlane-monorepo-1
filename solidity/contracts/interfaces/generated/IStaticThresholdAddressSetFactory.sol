// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IThresholdAddressFactory} from "../interfaces/IThresholdAddressFactory.sol";

interface IStaticThresholdAddressSetFactory {
    // ============ Functions ============
    function deploy(
        address[] calldata _values,
        uint8 _threshold
    ) external returns (address);
    function getAddress(
        address[] calldata _values,
        uint8 _threshold
    ) external view returns (address);
    function deploy(address[] calldata _values) external returns (address);
    function getAddress(
        address[] calldata _values
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IGasOracle} from "../../interfaces/IGasOracle.sol";

interface Iis {
    // ============ Events ============
    event RemoteGasDataSet(
        uint32 indexed remoteDomain,
        uint128 tokenExchangeRate,
        uint128 gasPrice
    );

    // ============ Functions ============
    function getExchangeRateAndGasPrice(
        uint32 _destinationDomain
    )
        external
        view
        override
        returns (uint128 tokenExchangeRate, uint128 gasPrice);
    function setRemoteGasDataConfigs(
        RemoteGasDataConfig[] calldata _configs
    ) external;
    function setRemoteGasData(RemoteGasDataConfig calldata _config) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface IStaticAggregationIsm {
    // ============ Functions ============
    function modulesAndThreshold(
        bytes calldata
    ) external view override returns (address[] memory, uint8);
}

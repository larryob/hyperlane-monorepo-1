// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface IRegressiveFee {
    // ============ Functions ============
    function feeType() external pure override returns (FeeType);
}

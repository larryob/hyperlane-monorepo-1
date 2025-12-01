// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface Ican {
    // ============ Functions ============
    function signatureCount(
        bytes calldata _metadata
    ) external pure override returns (uint256);
}

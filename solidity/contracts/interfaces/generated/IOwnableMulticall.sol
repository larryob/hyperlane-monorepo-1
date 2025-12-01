// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface IOwnableMulticall {
    // ============ Events ============
    event CommitmentSet(bytes32 indexed commitmentHash);
    event CommitmentExecuted(bytes32 indexed commitmentHash);

    // ============ Functions ============
    function multicall(CallLib.Call[] calldata calls) external payable;
    function setCommitment(bytes32 _commitment) external;
    function revealAndExecute(
        CallLib.Call[] calldata calls,
        bytes32 salt
    ) external payable returns (bytes32 executedCommitment);
}

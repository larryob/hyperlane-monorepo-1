// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface ICheckpointFraudProofs {
    // ============ Functions ============
    function storedCheckpointContainsMessage(
        address merkleTree,
        uint32 index,
        bytes32 messageId,
        bytes32[TREE_DEPTH] calldata proof
    ) external view returns (bool);
    function isLocal(
        Checkpoint calldata checkpoint
    ) external view returns (bool);
    function storeLatestCheckpoint(
        address merkleTree
    ) external returns (bytes32 root, uint32 index);
    function isPremature(
        Checkpoint calldata checkpoint
    ) external view onlyLocal(checkpoint) returns (bool);
    function isFraudulentMessageId(
        Checkpoint calldata checkpoint,
        bytes32[TREE_DEPTH] calldata proof,
        bytes32 actualMessageId
    )
        external
        view
        onlyLocal(checkpoint)
        onlyMessageInStoredCheckpoint(checkpoint, proof, actualMessageId)
        returns (bool);
    function isFraudulentRoot(
        Checkpoint calldata checkpoint,
        bytes32[TREE_DEPTH] calldata proof
    )
        external
        view
        onlyLocal(checkpoint)
        onlyMessageInStoredCheckpoint(checkpoint, proof, checkpoint.messageId)
        returns (bool);
}

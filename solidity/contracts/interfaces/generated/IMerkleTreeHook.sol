// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {Indexed} from "../libs/Indexed.sol";
import {IPostDispatchHook} from "../interfaces/hooks/IPostDispatchHook.sol";

interface IMerkleTreeHook {
    // ============ Events ============
    event InsertedIntoTree(bytes32 messageId, uint32 index);

    // ============ Functions ============
    function count() external view returns (uint32);
    function root() external view returns (bytes32);
    function tree() external view returns (MerkleLib.Tree memory);
    function latestCheckpoint() external view returns (bytes32, uint32);
    function hookType() external pure override returns (uint8);
}

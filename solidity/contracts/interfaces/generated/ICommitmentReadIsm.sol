// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {InterchainAccountMessageReveal} from "../../middleware/libs/InterchainAccountMessage.sol";
import {InterchainAccountRouter} from "../../middleware/InterchainAccountRouter.sol";

interface ICommitmentReadIsm {
    // ============ Functions ============
    function getCallsFromRevealMessage(
        bytes memory _message
    )
        external
        view
        returns (address ica, bytes32 salt, CallLib.Call[] memory _calls);
    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external returns (bool);
}

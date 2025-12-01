// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IAbstractMessageIdAuthorizedIsm {
    // ============ Events ============
    event ReceivedMessage(bytes32 indexed messageId, uint256 msgValue);

    // ============ Functions ============
    function setAuthorizedHook(bytes32 _hook) external initializer;
    function verify(
        bytes calldata,
        /*metadata*/ bytes calldata message
    ) external virtual returns (bool);
    function isVerified(bytes calldata message) external view returns (bool);
    function preVerifyMessage(
        bytes32 messageId,
        uint256 msgValue
    ) external payable virtual;
}

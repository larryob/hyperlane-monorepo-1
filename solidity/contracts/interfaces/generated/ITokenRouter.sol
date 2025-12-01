// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {Quote, ITokenBridge, ITokenFee} from "../../interfaces/ITokenBridge.sol";

interface ITokenRouter {
    // ============ Events ============
    event SentTransferRemote(
        uint32 indexed destination,
        bytes32 indexed recipient,
        uint256 amountOrId
    );
    event ReceivedTransferRemote(
        uint32 indexed origin,
        bytes32 indexed recipient,
        uint256 amountOrId
    );
    event FeeRecipientSet(address feeRecipient);

    // ============ Functions ============
    function token() external view virtual returns (address);
    function quoteTransferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) external view override returns (Quote[] memory quotes);
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) external payable virtual returns (bytes32 messageId);
    function _calculateFeesAndCharge(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount,
        uint256 _msgValue
    ) internal returns (uint256 externalFee, uint256 remainingNativeValue);
    function setFeeRecipient(address recipient) external;
    function feeRecipient() external view virtual returns (address);
}

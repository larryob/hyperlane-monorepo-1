// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {Indexed} from "./libs/Indexed.sol";
import {IInterchainSecurityModule, ISpecifiesInterchainSecurityModule} from "./interfaces/IInterchainSecurityModule.sol";
import {IPostDispatchHook} from "./interfaces/hooks/IPostDispatchHook.sol";
import {IMessageRecipient} from "./interfaces/IMessageRecipient.sol";
import {IMailbox} from "./interfaces/IMailbox.sol";

interface IMailbox {
    // ============ Events ============
    event DefaultIsmSet(address indexed module);
    event DefaultHookSet(address indexed hook);
    event RequiredHookSet(address indexed hook);

    // ============ Functions ============
    function initialize(
        address _owner,
        address _defaultIsm,
        address _defaultHook,
        address _requiredHook
    ) external initializer;
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external payable override returns (bytes32);
    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata hookMetadata
    ) external payable override returns (bytes32);
    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external view returns (uint256 fee);
    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata defaultHookMetadata
    ) external view returns (uint256 fee);
    function process(
        bytes calldata _metadata,
        bytes calldata _message
    ) external payable override;
    function processor(bytes32 _id) external view returns (address);
    function processedAt(bytes32 _id) external view returns (uint48);
    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata metadata,
        IPostDispatchHook hook
    ) external payable virtual returns (bytes32);
    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata metadata,
        IPostDispatchHook hook
    ) external view returns (uint256 fee);
    function delivered(bytes32 _id) external view override returns (bool);
    function setDefaultIsm(address _module) external;
    function setDefaultHook(address _hook) external;
    function setRequiredHook(address _hook) external;
    function recipientIsm(
        address _recipient
    ) external view returns (IInterchainSecurityModule);
}

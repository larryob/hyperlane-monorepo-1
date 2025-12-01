// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IMessageTransmitter} from "./../interfaces/cctp/IMessageTransmitter.sol";
import {IInterchainSecurityModule} from "./../interfaces/IInterchainSecurityModule.sol";
import {ITokenMessenger} from "./../interfaces/cctp/ITokenMessenger.sol";
import {IPostDispatchHook} from "../interfaces/hooks/IPostDispatchHook.sol";
import {IMessageHandler} from "../interfaces/cctp/IMessageHandler.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Ito {
    // ============ Events ============
    event DomainAdded(uint32 indexed hyperlaneDomain, uint32 circleDomain);

    // ============ Errors ============
    error InvalidCCTPVersion();
    error CircleDomainNotConfigured();
    error HyperlaneDomainNotConfigured();
    error InvalidTokenMessageRecipient();
    error InvalidCircleRecipient();
    error NotMessageTransmitter();
    error UnauthorizedCircleSender();
    error MessageNotDispatched();
    error InvalidBurnSender();
    error InvalidMintAmount();
    error InvalidMintRecipient();
    error InvalidMessageId();

    // ============ Functions ============
    function getCCTPAttestation(
        bytes calldata _message
    )
        external
        view
        returns (bytes memory cctpMessage, bytes memory attestation);
    function token() external view override returns (address);
    function initialize(
        address _hook,
        address _owner,
        string[] memory __urls
    ) external initializer;
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) external payable override returns (bytes32 messageId);
    function interchainSecurityModule()
        external
        view
        override
        returns (IInterchainSecurityModule);
    function addDomain(uint32 _hyperlaneDomain, uint32 _circleDomain) external;
    function addDomains(Domain[] memory domains) external;
    function hyperlaneDomainToCircleDomain(
        uint32 _hyperlaneDomain
    ) external view returns (uint32);
    function circleDomainToHyperlaneDomain(
        uint32 _circleDomain
    ) external view returns (uint32);
    function verify(
        bytes calldata _metadata,
        bytes calldata _hyperlaneMessage
    ) external returns (bool);
    function hookType() external pure override returns (uint8);
}

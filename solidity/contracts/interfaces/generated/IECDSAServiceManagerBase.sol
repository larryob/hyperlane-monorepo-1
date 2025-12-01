// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {ISignatureUtils} from "../interfaces/avs/vendored/ISignatureUtils.sol";
import {IAVSDirectory} from "../interfaces/avs/vendored/IAVSDirectory.sol";
import {IServiceManager} from "../interfaces/avs/vendored/IServiceManager.sol";
import {IServiceManagerUI} from "../interfaces/avs/vendored/IServiceManagerUI.sol";
import {IDelegationManager} from "../interfaces/avs/vendored/IDelegationManager.sol";
import {IStrategy} from "../interfaces/avs/vendored/IStrategy.sol";
import {IPaymentCoordinator} from "../interfaces/avs/vendored/IPaymentCoordinator.sol";
import {Quorum} from "../interfaces/avs/vendored/IECDSAStakeRegistryEventsAndErrors.sol";

interface IECDSAServiceManagerBase {
    // ============ Events ============
    event OperatorRegisteredToAVS(address indexed operator);
    event OperatorDeregisteredFromAVS(address indexed operator);

    // ============ Functions ============
    function updateAVSMetadataURI(string memory _metadataURI) external virtual;
    function payForRange(
        IPaymentCoordinator.RangePayment[] calldata rangePayments
    ) external virtual;
    function registerOperatorToAVS(
        address operator,
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature
    ) external virtual onlyStakeRegistry;
    function deregisterOperatorFromAVS(
        address operator
    ) external virtual onlyStakeRegistry;
    function getRestakeableStrategies()
        external
        view
        virtual
        returns (address[] memory);
    function getOperatorRestakedStrategies(
        address _operator
    ) external view virtual returns (address[] memory);
    function setPaymentCoordinator(
        address _paymentCoordinator
    ) external virtual;
}

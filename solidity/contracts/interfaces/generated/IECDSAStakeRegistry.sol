// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {StrategyParams} from "../interfaces/avs/vendored/IECDSAStakeRegistryEventsAndErrors.sol";
import {IStrategy} from "../interfaces/avs/vendored/IStrategy.sol";
import {IDelegationManager} from "../interfaces/avs/vendored/IDelegationManager.sol";
import {ISignatureUtils} from "../interfaces/avs/vendored/ISignatureUtils.sol";
import {IServiceManager} from "../interfaces/avs/vendored/IServiceManager.sol";
import {IERC1271Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";

interface IECDSAStakeRegistry {
    // ============ Functions ============
    function initialize(
        address _serviceManager,
        uint256 _thresholdWeight,
        Quorum memory _quorum
    ) external initializer;
    function registerOperatorWithSignature(
        ISignatureUtils.SignatureWithSaltAndExpiry memory _operatorSignature,
        address _signingKey
    ) external;
    function deregisterOperator() external;
    function updateOperatorSigningKey(address _newSigningKey) external;
    function updateOperators(address[] memory _operators) external;
    function updateQuorumConfig(
        Quorum memory _quorum,
        address[] memory _operators
    ) external;
    function updateMinimumWeight(
        uint256 _newMinimumWeight,
        address[] memory _operators
    ) external;
    function updateStakeThreshold(uint256 _thresholdWeight) external;
    function isValidSignature(
        bytes32 _dataHash,
        bytes memory _signatureData
    ) external view returns (bytes4);
    function quorum() external view returns (Quorum memory);
    function getLastestOperatorSigningKey(
        address _operator
    ) external view returns (address);
    function getOperatorSigningKeyAtBlock(
        address _operator,
        uint256 _blockNumber
    ) external view returns (address);
    function getLastCheckpointOperatorWeight(
        address _operator
    ) external view returns (uint256);
    function getLastCheckpointTotalWeight() external view returns (uint256);
    function getLastCheckpointThresholdWeight() external view returns (uint256);
    function getOperatorWeightAtBlock(
        address _operator,
        uint32 _blockNumber
    ) external view returns (uint256);
    function getLastCheckpointTotalWeightAtBlock(
        uint32 _blockNumber
    ) external view returns (uint256);
    function getLastCheckpointThresholdWeightAtBlock(
        uint32 _blockNumber
    ) external view returns (uint256);
    function operatorRegistered(address _operator) external view returns (bool);
    function minimumWeight() external view returns (uint256);
    function getOperatorWeight(
        address _operator
    ) external view returns (uint256);
    function updateOperatorsForQuorum(
        address[][] memory operatorsPerQuorum,
        bytes memory
    ) external;
}

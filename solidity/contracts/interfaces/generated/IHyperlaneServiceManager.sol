// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IAVSDirectory} from "../interfaces/avs/vendored/IAVSDirectory.sol";
import {IRemoteChallenger} from "../interfaces/avs/IRemoteChallenger.sol";
import {ISlasher} from "../interfaces/avs/vendored/ISlasher.sol";

interface IHyperlaneServiceManager {
    // ============ Events ============
    event OperatorEnrolledToChallenger(
        address operator,
        IRemoteChallenger challenger
    );
    event OperatorQueuedUnenrollmentFromChallenger(
        address operator,
        IRemoteChallenger challenger,
        uint256 unenrollmentStartBlock,
        uint256 challengeDelayBlocks
    );
    event OperatorUnenrolledFromChallenger(
        address operator,
        IRemoteChallenger challenger,
        uint256 unenrollmentEndBlock
    );

    // ============ Functions ============
    function initialize(address _owner) external initializer;
    function enrollIntoChallengers(
        IRemoteChallenger[] memory _challengers
    ) external;
    function startUnenrollment(
        IRemoteChallenger[] memory _challengers
    ) external;
    function completeUnenrollment(address[] memory _challengers) external;
    function setSlasher(ISlasher _slasher) external;
    function getChallengerEnrollment(
        address _operator,
        IRemoteChallenger _challenger
    ) external view returns (Enrollment memory enrollment);
    function freezeOperator(
        address operator
    ) external virtual onlyEnrolledChallenger(operator);
    function getOperatorChallengers(
        address _operator
    ) external view returns (address[] memory);
    function enrollIntoChallenger(IRemoteChallenger challenger) external;
    function startUnenrollment(IRemoteChallenger challenger) external;
    function completeUnenrollment(address challenger) external;
}

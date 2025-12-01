// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IValidatorAnnounce} from "../../interfaces/IValidatorAnnounce.sol";

interface IValidatorAnnounce {
    // ============ Events ============
    event ValidatorAnnouncement(
        address indexed validator,
        string storageLocation
    );

    // ============ Functions ============
    function announce(
        address _validator,
        string calldata _storageLocation,
        bytes calldata _signature
    ) external returns (bool);
    function getAnnouncedStorageLocations(
        address[] calldata _validators
    ) external view returns (string[][] memory);
    function getAnnouncedValidators() external view returns (address[] memory);
    function getAnnouncementDigest(
        string memory _storageLocation
    ) external view returns (bytes32);
}

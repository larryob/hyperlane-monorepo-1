// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IStandardBridge} from "../../interfaces/optimism/IStandardBridge.sol";
import {Quote, ITokenBridge} from "../../interfaces/ITokenBridge.sol";
import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";

interface IOpL2NativeTokenBridge {
    // ============ Functions ============
    function initialize(address _hook, address _owner) external initializer;
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) external payable override returns (bytes32);
    function handle(uint32, bytes32, bytes calldata) external payable override;
    function token() external view override returns (address);
    function initialize(
        address _owner,
        string[] memory _urls
    ) external initializer;
    function transferRemote(
        uint32,
        bytes32,
        uint256
    ) external payable override returns (bytes32);
    function token() external view override returns (address);
    function interchainSecurityModule()
        external
        view
        override
        returns (IInterchainSecurityModule);
}

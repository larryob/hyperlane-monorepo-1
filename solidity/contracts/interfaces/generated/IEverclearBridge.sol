// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {ITokenBridge, Quote} from "../../interfaces/ITokenBridge.sol";
import {IEverclearAdapter, IEverclear, IEverclearSpoke} from "../../interfaces/IEverclearAdapter.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEverclearBridge {
    // ============ Events ============
    event FeeParamsUpdated(uint32 destination, uint256 fee, uint256 deadline);
    event OutputAssetSet(uint32 destination, bytes32 outputAsset);

    // ============ Functions ============
    function initialize(address _hook, address _owner) external initializer;
    function setFeeParams(
        uint32 _destination,
        uint256 _fee,
        uint256 _deadline,
        bytes calldata _sig
    ) external;
    function setOutputAsset(OutputAssetInfo calldata _outputAssetInfo) external;
    function setOutputAssetsBatch(
        OutputAssetInfo[] calldata _outputAssetInfos
    ) external;
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) external payable override returns (bytes32 messageId);
    function token() external view override returns (address);
    function token() external pure override returns (address);
}

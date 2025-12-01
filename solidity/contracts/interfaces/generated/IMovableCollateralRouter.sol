// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {ITokenBridge, Quote} from "../../interfaces/ITokenBridge.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMovableCollateralRouter {
    // ============ Events ============
    event CollateralMoved(
        uint32 indexed domain,
        bytes32 recipient,
        uint256 amount,
        address indexed rebalancer
    );

    // ============ Functions ============
    function allowedRebalancers() external view returns (address[] memory);
    function allowedRecipient(uint32 domain) external view returns (bytes32);
    function allowedBridges(
        uint32 domain
    ) external view returns (address[] memory);
    function setRecipient(uint32 domain, bytes32 recipient) external;
    function removeRecipient(uint32 domain) external;
    function addBridge(uint32 domain, ITokenBridge bridge) external;
    function removeBridge(uint32 domain, ITokenBridge bridge) external;
    function approveTokenForBridge(IERC20 token, ITokenBridge bridge) external;
    function addRebalancer(address rebalancer) external;
    function removeRebalancer(address rebalancer) external;
    function rebalance(
        uint32 domain,
        uint256 collateralAmount,
        ITokenBridge bridge
    ) external payable onlyRebalancer onlyAllowedBridge(domain, bridge);
}

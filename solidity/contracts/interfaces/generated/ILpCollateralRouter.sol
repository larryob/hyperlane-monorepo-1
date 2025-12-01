// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ILpCollateralRouter {
    // ============ Events ============
    event Donation(address sender, uint256 amount);

    // ============ Functions ============
    function totalAssets() external view override returns (uint256);
    function asset() external view override returns (address);
    function donate(uint256 amount) external payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {ITokenBridge, Quote} from "../interfaces/ITokenBridge.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHypERC20Collateral {
    // ============ Functions ============
    function initialize(
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) external initializer;
    function token() external view override returns (address);
}

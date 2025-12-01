// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IXERC20} from "../interfaces/IXERC20.sol";

interface IHypXERC20 {
    // ============ Functions ============
    function initialize(
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) external initializer;
    function token() external view override returns (address);
}

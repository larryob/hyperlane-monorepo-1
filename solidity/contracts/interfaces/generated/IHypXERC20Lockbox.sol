// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IXERC20Lockbox} from "../interfaces/IXERC20Lockbox.sol";
import {IXERC20, IERC20} from "../interfaces/IXERC20.sol";

interface IHypXERC20Lockbox {
    // ============ Functions ============
    function approveLockbox() external;
    function initialize(
        address _hook,
        address _ism,
        address _owner
    ) external initializer;
    function token() external view override returns (address);
}

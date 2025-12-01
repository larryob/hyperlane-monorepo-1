// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IFiatToken} from "../interfaces/IFiatToken.sol";

interface IHypFiatToken {
    // ============ Functions ============
    function initialize(
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) external initializer;
    function token() external view override returns (address);
}

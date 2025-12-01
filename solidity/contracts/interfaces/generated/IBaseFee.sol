// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {ITokenFee, Quote} from "../../interfaces/ITokenBridge.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBaseFee {
    // ============ Functions ============
    function claim(address beneficiary) external;
    function quoteTransferRemote(
        uint32 /*_destination*/,
        bytes32 /*_recipient*/,
        uint256 _amount
    ) external view virtual returns (Quote[] memory quotes);
    function feeType() external view virtual returns (FeeType);
}

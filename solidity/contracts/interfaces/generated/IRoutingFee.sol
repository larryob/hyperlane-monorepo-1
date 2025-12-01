// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {ITokenFee, Quote} from "../../interfaces/ITokenBridge.sol";

interface IRoutingFee {
    // ============ Events ============
    event FeeContractSet(uint32 destination, address feeContract);

    // ============ Functions ============
    function setFeeContract(uint32 destination, address feeContract) external;
    function quoteTransferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) external view override returns (Quote[] memory quotes);
    function feeType() external pure override returns (FeeType);
}

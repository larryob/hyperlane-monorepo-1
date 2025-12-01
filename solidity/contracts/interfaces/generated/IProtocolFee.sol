// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IPostDispatchHook} from "../interfaces/hooks/IPostDispatchHook.sol";

interface IProtocolFee {
    // ============ Events ============
    event ProtocolFeeSet(uint256 protocolFee);
    event BeneficiarySet(address beneficiary);
    event ProtocolFeePaid(address indexed sender, uint256 fee);

    // ============ Functions ============
    function hookType() external pure override returns (uint8);
    function setProtocolFee(uint256 _protocolFee) external;
    function setBeneficiary(address _beneficiary) external;
    function collectProtocolFees() external;
}

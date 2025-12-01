// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IMailbox} from "../../interfaces/IMailbox.sol";
import {IMessageRecipient} from "../../interfaces/IMessageRecipient.sol";
import {IOptimismPortal} from "../../interfaces/optimism/IOptimismPortal.sol";
import {IOptimismPortal2} from "../../interfaces/optimism/IOptimismPortal2.sol";
import {IInterchainSecurityModule, ISpecifiesInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";

interface IOPL2ToL1CcipReadIsm {
    // ============ Functions ============
    function getWithdrawalProof(
        bytes calldata _message
    )
        external
        view
        returns (
            IOptimismPortal.WithdrawalTransaction memory _tx,
            uint256 _disputeGameIndex,
            IOptimismPortal.OutputRootProof memory _outputRootProof,
            bytes[] memory _withdrawalProof
        );
    function getFinalizeWithdrawalTx(
        bytes calldata _message
    ) external view returns (IOptimismPortal.WithdrawalTransaction memory _tx);
    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external override returns (bool);
}

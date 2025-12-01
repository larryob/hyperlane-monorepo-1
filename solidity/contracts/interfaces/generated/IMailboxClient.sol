// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IMailbox} from "../interfaces/IMailbox.sol";
import {IPostDispatchHook} from "../interfaces/hooks/IPostDispatchHook.sol";
import {IInterchainSecurityModule} from "../interfaces/IInterchainSecurityModule.sol";

interface IMailboxClient {
    // ============ Events ============
    event HookSet(address _hook);
    event IsmSet(address _ism);

    // ============ Functions ============
    function interchainSecurityModule()
        external
        view
        virtual
        returns (IInterchainSecurityModule);
    function setHook(address _hook) external virtual onlyContractOrNull(_hook);
    function setInterchainSecurityModule(
        address _module
    ) external onlyContractOrNull(_module);
}

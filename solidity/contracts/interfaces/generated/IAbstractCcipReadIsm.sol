// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../../interfaces/IInterchainSecurityModule.sol";
import {ICcipReadIsm} from "../../interfaces/isms/ICcipReadIsm.sol";

interface IAbstractCcipReadIsm {
    // ============ Events ============
    event UrlsChanged(string[] newUrls);

    // ============ Functions ============
    function setUrls(string[] memory __urls) external;
    function getOffchainVerifyInfo(
        bytes calldata _message
    ) external view override;
    function urls() external view returns (string[] memory);
}

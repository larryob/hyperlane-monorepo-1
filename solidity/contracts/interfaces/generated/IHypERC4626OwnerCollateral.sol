// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface IHypERC4626OwnerCollateral {
    // ============ Events ============
    event ExcessSharesSwept(uint256 amount, uint256 assetsRedeemed);

    // ============ Functions ============
    function sweep() external;
}

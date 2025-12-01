// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface Iimplements {
    // ============ Events ============
    event ExchangeRateUpdated(uint256 newExchangeRate, uint32 rateUpdateNonce);

    // ============ Functions ============
    function totalSupply() external view override returns (uint256);
    function balanceOf(
        address account
    ) external view override returns (uint256);
    function totalShares() external view returns (uint256);
    function shareBalanceOf(address account) external view returns (uint256);
    function assetsToShares(uint256 _amount) external view returns (uint256);
    function sharesToAssets(uint256 _shares) external view returns (uint256);
}

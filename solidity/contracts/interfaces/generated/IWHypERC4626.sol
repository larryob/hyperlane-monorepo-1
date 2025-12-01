// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface IWHypERC4626 {
    // ============ Functions ============
    function wrap(uint256 _underlyingAmount) external returns (uint256);
    function unwrap(uint256 _wrappedAmount) external returns (uint256);
    function getWrappedAmount(
        uint256 _underlyingAmount
    ) external view returns (uint256);
    function getUnderlyingAmount(
        uint256 _wrappedAmount
    ) external view returns (uint256);
    function wrappedPerUnderlying() external view returns (uint256);
    function underlyingPerWrapped() external view returns (uint256);
    function decimals() external view override returns (uint8);
}

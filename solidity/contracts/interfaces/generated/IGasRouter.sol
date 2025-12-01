// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface IGasRouter {
    // ============ Events ============
    event GasSet(uint32 domain, uint256 gas);

    // ============ Functions ============
    function setDestinationGas(GasRouterConfig[] calldata gasConfigs) external;
    function setDestinationGas(uint32 domain, uint256 gas) external;
    function quoteGasPayment(
        uint32 _destinationDomain
    ) external view virtual returns (uint256);
}

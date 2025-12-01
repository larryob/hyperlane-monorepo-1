// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface Iused {
    // ============ Events ============
    event RateLimitSet(uint256 _oldCapacity, uint256 _newCapacity);
    event ConsumedFilledLevel(uint256 filledLevel, uint256 lastUpdated);

    // ============ Errors ============
    error RateLimitExceeded(uint256 newLimit, uint256 targetLimit);

    // ============ Functions ============
    function maxCapacity() external view returns (uint256);
    function calculateCurrentLevel() external view returns (uint256);
    function setRefillRate(uint256 _capacity) external returns (uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {ITokenBridge} from "./ITokenBridge.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IERC4626RebalancingBridge
 * @notice Interface for a local rebalancing bridge that wraps an ERC4626 vault for yield generation.
 * @dev This bridge operates locally (same domain as the mailbox) and allows:
 *      - Moving collateral from a warp route into an ERC4626 vault for yield generation
 *      - Withdrawing principal assets back to the warp route
 *      - Claiming yield and sending it to the warp route's fee recipient
 */
interface IERC4626RebalancingBridge is ITokenBridge {
    // ============ Events ============

    /**
     * @notice Emitted when collateral is deposited into the vault
     * @param amount The amount of tokens deposited
     * @param shares The number of vault shares received
     */
    event Deposited(uint256 amount, uint256 shares);

    /**
     * @notice Emitted when principal is withdrawn from the vault
     * @param amount The amount of tokens withdrawn
     * @param recipient The recipient of the withdrawn tokens
     */
    event PrincipalWithdrawn(uint256 amount, address recipient);

    /**
     * @notice Emitted when yield is claimed from the vault
     * @param amount The amount of yield claimed
     * @param recipient The recipient of the yield (fee recipient)
     */
    event YieldClaimed(uint256 amount, address recipient);

    // ============ External Functions ============

    /**
     * @notice Withdraw principal assets back to the warp route
     * @param _amount The amount of principal to withdraw
     * @dev Only callable by authorized rebalancer or owner
     */
    function withdrawPrincipal(uint256 _amount) external;

    /**
     * @notice Claim accumulated yield and send to the yield recipient
     * @return yieldAmount The amount of yield claimed
     * @dev Anyone can call this function to claim yield
     */
    function claimYield() external returns (uint256 yieldAmount);

    /**
     * @notice Set the yield recipient address
     * @param _yieldRecipient The address to receive claimed yield
     * @dev Only callable by the owner
     */
    function setYieldRecipient(address _yieldRecipient) external;

    // ============ View Functions ============

    /**
     * @notice Returns the ERC4626 vault being used for yield generation
     */
    function vault() external view returns (IERC4626);

    /**
     * @notice Returns the underlying token (vault's asset)
     */
    function token() external view returns (IERC20);

    /**
     * @notice Returns the warp route this bridge is configured for
     */
    function warpRoute() external view returns (address);

    /**
     * @notice Returns the address that receives claimed yield
     */
    function yieldRecipient() external view returns (address);

    /**
     * @notice Returns the total principal deposited (excludes yield)
     */
    function principalDeposited() external view returns (uint256);

    /**
     * @notice Returns the current pending yield available to claim
     * @return yield The amount of yield that can be claimed
     */
    function pendingYield() external view returns (uint256 yield);

    /**
     * @notice Returns the total assets held in the vault (principal + yield)
     */
    function totalVaultAssets() external view returns (uint256);
}

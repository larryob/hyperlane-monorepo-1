// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============
import {IERC4626RebalancingBridge} from "../../interfaces/IERC4626RebalancingBridge.sol";
import {ITokenBridge, ITokenFee, Quote} from "../../interfaces/ITokenBridge.sol";
import {TokenRouter} from "../libs/TokenRouter.sol";
import {IMailbox} from "../../interfaces/IMailbox.sol";
import {PackageVersioned} from "../../PackageVersioned.sol";

// ============ External Imports ============
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ERC4626RebalancingBridge
 * @author Hyperlane Team
 * @notice A local rebalancing bridge that wraps an ERC4626 vault for yield generation on warp routes.
 * @dev This bridge enables warp route owners to configure a local (domain == mailbox.localDomain)
 *      rebalancing mechanism that allows the rebalancer to:
 *      1. Move collateral into an ERC4626 vault for yield generation via `transferRemote`
 *      2. Withdraw principal assets back to the warp route via `withdrawPrincipal`
 *      3. Claim yield and send it to the warp route's fee recipient via `claimYield`
 *
 *      The bridge implements ITokenBridge to integrate with MovableCollateralRouter.rebalance(),
 *      but operates locally without actually dispatching cross-chain messages.
 */
contract ERC4626RebalancingBridge is
    IERC4626RebalancingBridge,
    Ownable,
    PackageVersioned
{
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ============ Constants ============

    /// @notice The ERC4626 vault used for yield generation
    IERC4626 public immutable override vault;

    /// @notice The underlying token (vault's asset)
    IERC20 public immutable override token;

    /// @notice The warp route this bridge is configured for
    address public immutable override warpRoute;

    /// @notice The mailbox for domain verification
    IMailbox public immutable mailbox;

    /// @notice The local domain ID
    uint32 public immutable localDomain;

    // ============ State Variables ============

    /// @notice Total principal deposited (excludes yield)
    uint256 public override principalDeposited;

    /// @notice The address that receives claimed yield
    address public override yieldRecipient;

    // ============ Events ============

    event YieldRecipientSet(address yieldRecipient);

    // ============ Errors ============

    error OnlyWarpRoute();
    error OnlyLocalDomain();
    error ExceedsPrincipal();
    error NoYieldRecipient();
    error NoYieldAvailable();
    error InvalidVault();
    error InvalidWarpRoute();
    error InvalidYieldRecipient();

    // ============ Constructor ============

    /**
     * @notice Constructs the ERC4626RebalancingBridge
     * @param _vault The ERC4626 vault to use for yield generation
     * @param _warpRoute The warp route this bridge is configured for
     * @param _owner The owner of the bridge (typically the warp route owner)
     */
    constructor(
        IERC4626 _vault,
        address _warpRoute,
        address _owner
    ) Ownable() {
        if (address(_vault) == address(0)) revert InvalidVault();
        if (_warpRoute == address(0)) revert InvalidWarpRoute();

        vault = _vault;
        token = IERC20(_vault.asset());
        warpRoute = _warpRoute;

        // Get mailbox from warp route to verify local domain
        mailbox = TokenRouter(_warpRoute).mailbox();
        localDomain = mailbox.localDomain();

        // Approve vault to spend tokens
        token.safeApprove(address(_vault), type(uint256).max);

        _transferOwnership(_owner);
    }

    // ============ Modifiers ============

    modifier onlyWarpRoute() {
        if (msg.sender != warpRoute) revert OnlyWarpRoute();
        _;
    }

    modifier onlyLocalDomain(uint32 _domain) {
        if (_domain != localDomain) revert OnlyLocalDomain();
        _;
    }

    // ============ ITokenBridge Implementation ============

    /**
     * @inheritdoc ITokenBridge
     * @notice Deposits collateral into the ERC4626 vault for yield generation
     * @dev This function is called by MovableCollateralRouter.rebalance()
     *      Only works for local domain (domain == mailbox.localDomain)
     * @param _destination Must be the local domain
     * @param _recipient Ignored for local vault operations
     * @param _amount The amount of tokens to deposit into the vault
     * @return messageId A pseudo message ID (not actually dispatching a message)
     */
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    )
        external
        payable
        override
        onlyWarpRoute
        onlyLocalDomain(_destination)
        returns (bytes32)
    {
        // Pull tokens from warp route (warp route has approved this bridge)
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Deposit into vault
        uint256 shares = vault.deposit(_amount, address(this));

        // Track principal
        principalDeposited += _amount;

        emit Deposited(_amount, shares);

        // Return a pseudo message ID (not actually dispatching a message)
        return
            keccak256(
                abi.encodePacked(
                    _destination,
                    _recipient,
                    _amount,
                    block.timestamp,
                    block.number
                )
            );
    }

    /**
     * @inheritdoc ITokenFee
     * @notice Returns quotes for the transfer (no fees for local vault operations)
     * @param _destination The destination domain (must be local)
     * @param _recipient The recipient (ignored for local operations)
     * @param _amount The amount to transfer
     * @return quotes Array of quotes with no fees
     */
    function quoteTransferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) external view override returns (Quote[] memory quotes) {
        // Silence unused variable warnings
        _destination;
        _recipient;

        quotes = new Quote[](3);
        // No native fee for local vault operations
        quotes[0] = Quote({token: address(0), amount: 0});
        // The collateral amount to transfer (pulled from warp route)
        quotes[1] = Quote({token: address(token), amount: _amount});
        // No external fee
        quotes[2] = Quote({token: address(token), amount: 0});
    }

    // ============ External Functions ============

    /**
     * @inheritdoc IERC4626RebalancingBridge
     * @notice Withdraw principal assets back to the warp route
     * @param _amount The amount of principal to withdraw
     * @dev Only callable by the bridge owner (typically the warp route owner)
     */
    function withdrawPrincipal(uint256 _amount) external override onlyOwner {
        if (_amount > principalDeposited) revert ExceedsPrincipal();

        // Update principal before withdrawal
        principalDeposited -= _amount;

        // Withdraw from vault directly to warp route
        vault.withdraw(_amount, warpRoute, address(this));

        emit PrincipalWithdrawn(_amount, warpRoute);
    }

    /**
     * @inheritdoc IERC4626RebalancingBridge
     * @notice Claim accumulated yield and send to the yield recipient
     * @return yieldAmount The amount of yield claimed
     * @dev Anyone can call this function to claim yield and distribute it
     */
    function claimYield() external override returns (uint256 yieldAmount) {
        yieldAmount = pendingYield();
        if (yieldAmount == 0) revert NoYieldAvailable();

        address recipient = yieldRecipient;
        if (recipient == address(0)) revert NoYieldRecipient();

        // Withdraw yield directly to yield recipient
        vault.withdraw(yieldAmount, recipient, address(this));

        emit YieldClaimed(yieldAmount, recipient);
    }

    /**
     * @inheritdoc IERC4626RebalancingBridge
     * @notice Set the yield recipient address
     * @param _yieldRecipient The address to receive claimed yield
     * @dev Only callable by the owner
     */
    function setYieldRecipient(address _yieldRecipient) external override onlyOwner {
        if (_yieldRecipient == address(0)) revert InvalidYieldRecipient();
        yieldRecipient = _yieldRecipient;
        emit YieldRecipientSet(_yieldRecipient);
    }

    // ============ View Functions ============

    /**
     * @inheritdoc IERC4626RebalancingBridge
     * @notice Returns the current pending yield available to claim
     * @return yield The amount of yield that can be claimed
     */
    function pendingYield() public view override returns (uint256 yield) {
        uint256 totalAssets = totalVaultAssets();
        if (totalAssets > principalDeposited) {
            yield = totalAssets - principalDeposited;
        }
    }

    /**
     * @inheritdoc IERC4626RebalancingBridge
     * @notice Returns the total assets held in the vault (principal + yield)
     */
    function totalVaultAssets() public view override returns (uint256) {
        return vault.maxWithdraw(address(this));
    }

    /**
     * @notice Returns the number of vault shares held by this bridge
     */
    function vaultShares() external view returns (uint256) {
        return vault.balanceOf(address(this));
    }

    /**
     * @notice Receive function to accept native token refunds
     * @dev Required in case of native token refunds from failed operations
     */
    receive() external payable {}
}

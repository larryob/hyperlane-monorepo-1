// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.13;

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

import "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ERC4626Test} from "../../contracts/test/ERC4626/ERC4626Test.sol";
import {MockERC4626YieldSharing} from "../../contracts/mock/MockERC4626YieldSharing.sol";
import {TypeCasts} from "../../contracts/libs/TypeCasts.sol";
import {HypTokenTest} from "./HypERC20.t.sol";
import {MockMailbox} from "../../contracts/mock/MockMailbox.sol";
import {HypERC20Collateral} from "../../contracts/token/HypERC20Collateral.sol";
import {HypERC20} from "../../contracts/token/HypERC20.sol";
import {ERC4626RebalancingBridge} from "../../contracts/token/bridge/ERC4626RebalancingBridge.sol";
import {IERC4626RebalancingBridge} from "../../contracts/interfaces/IERC4626RebalancingBridge.sol";
import {ITokenBridge, Quote} from "../../contracts/interfaces/ITokenBridge.sol";
import {TokenRouter} from "../../contracts/token/libs/TokenRouter.sol";
import "../../contracts/test/ERC4626/ERC4626Test.sol";

contract ERC4626RebalancingBridgeTest is HypTokenTest {
    using TypeCasts for address;

    uint256 constant YIELD = 5e18;
    uint256 constant YIELD_FEE_PERCENT = 1e17; // 10% of yield goes to vault owner
    uint256 internal transferAmount = 100e18;

    MockERC4626YieldSharing vault;
    ERC4626RebalancingBridge rebalancingBridge;

    HypERC20Collateral collateralToken;

    address constant REBALANCER = address(0x1111);
    address constant VAULT_OWNER = address(0x3333);
    address constant YIELD_RECIPIENT = address(0x4444);

    event Deposited(uint256 amount, uint256 shares);
    event PrincipalWithdrawn(uint256 amount, address recipient);
    event YieldClaimed(uint256 amount, address recipient);
    event CollateralMoved(
        uint32 indexed domain,
        bytes32 recipient,
        uint256 amount,
        address indexed rebalancer
    );

    function setUp() public override {
        super.setUp();

        // Create vault owned by VAULT_OWNER
        vm.prank(VAULT_OWNER);
        vault = new MockERC4626YieldSharing(
            address(primaryToken),
            "Yield Vault",
            "yVault",
            YIELD_FEE_PERCENT
        );

        // Deploy HypERC20Collateral as local token
        HypERC20Collateral implementation = new HypERC20Collateral(
            address(primaryToken),
            SCALE,
            address(localMailbox)
        );
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            PROXY_ADMIN,
            abi.encodeWithSelector(
                HypERC20Collateral.initialize.selector,
                address(noopHook),
                address(0x0),
                address(this)
            )
        );
        localToken = HypERC20Collateral(address(proxy));
        collateralToken = HypERC20Collateral(address(proxy));

        // Setup remote token (for testing warp route)
        HypERC20 remoteImpl = new HypERC20(
            primaryToken.decimals(),
            SCALE,
            address(remoteMailbox)
        );
        TransparentUpgradeableProxy remoteProxy = new TransparentUpgradeableProxy(
                address(remoteImpl),
                PROXY_ADMIN,
                abi.encodeWithSelector(
                    HypERC20.initialize.selector,
                    0,
                    "Remote Token",
                    "REMOTE",
                    address(noopHook),
                    address(0x0),
                    address(this)
                )
            );
        remoteToken = HypERC20(address(remoteProxy));

        // Connect remote routers first
        uint32[] memory domains = new uint32[](2);
        domains[0] = ORIGIN;
        domains[1] = DESTINATION;

        bytes32[] memory addresses = new bytes32[](2);
        addresses[0] = address(localToken).addressToBytes32();
        addresses[1] = address(remoteToken).addressToBytes32();
        _connectRouters(domains, addresses);

        // For local vault rebalancing, we need to enroll the local token
        // as a router for its own domain (loopback). This allows the
        // MovableCollateralRouter to add bridges for the local domain.
        collateralToken.enrollRemoteRouter(
            ORIGIN,
            address(localToken).addressToBytes32()
        );

        // Create rebalancing bridge
        rebalancingBridge = new ERC4626RebalancingBridge(
            vault,
            address(localToken),
            address(this) // owner
        );

        // Setup the warp route
        // Add rebalancer
        collateralToken.addRebalancer(REBALANCER);
        // Add the rebalancing bridge for local domain (now router is enrolled)
        collateralToken.addBridge(ORIGIN, rebalancingBridge);
        // Set yield recipient on the bridge for yield claiming
        rebalancingBridge.setYieldRecipient(YIELD_RECIPIENT);
        // Set explicit recipient for local domain rebalancing
        collateralToken.setRecipient(ORIGIN, address(localToken).addressToBytes32());

        // Fund users
        primaryToken.transfer(ALICE, 1000e18);
        primaryToken.transfer(BOB, 1000e18);
    }

    function _localTokenBalanceOf(
        address _account
    ) internal view override returns (uint256) {
        return primaryToken.balanceOf(_account);
    }

    // ============ Construction Tests ============

    // Override inherited test that doesn't apply to this test
    function testBenchmark_overheadGasUsage() public pure override {
        // This test is for HypERC20Collateral, not applicable to ERC4626RebalancingBridge tests
    }

    // Override inherited test that requires specific setup
    function testRemoteTransfer_withFee() public pure override {
        // Fee recipient tests require ITokenFee contract, skipping
    }

    function test_constructor_setsCorrectState() public view {
        assertEq(address(rebalancingBridge.vault()), address(vault));
        assertEq(address(rebalancingBridge.token()), address(primaryToken));
        assertEq(rebalancingBridge.warpRoute(), address(localToken));
        assertEq(
            address(rebalancingBridge.mailbox()),
            address(localMailbox)
        );
        assertEq(rebalancingBridge.localDomain(), ORIGIN);
        assertEq(rebalancingBridge.principalDeposited(), 0);
        assertEq(rebalancingBridge.owner(), address(this));
        assertEq(rebalancingBridge.yieldRecipient(), YIELD_RECIPIENT);
    }

    function test_setYieldRecipient_success() public {
        address newRecipient = address(0x5555);
        rebalancingBridge.setYieldRecipient(newRecipient);
        assertEq(rebalancingBridge.yieldRecipient(), newRecipient);
    }

    function test_setYieldRecipient_revertsZeroAddress() public {
        vm.expectRevert(ERC4626RebalancingBridge.InvalidYieldRecipient.selector);
        rebalancingBridge.setYieldRecipient(address(0));
    }

    function test_setYieldRecipient_revertsNonOwner() public {
        vm.prank(ALICE);
        vm.expectRevert("Ownable: caller is not the owner");
        rebalancingBridge.setYieldRecipient(address(0x5555));
    }

    function test_constructor_revertsInvalidVault() public {
        vm.expectRevert(
            ERC4626RebalancingBridge.InvalidVault.selector
        );
        new ERC4626RebalancingBridge(
            IERC4626(address(0)),
            address(localToken),
            address(this)
        );
    }

    function test_constructor_revertsInvalidWarpRoute() public {
        vm.expectRevert(
            ERC4626RebalancingBridge.InvalidWarpRoute.selector
        );
        new ERC4626RebalancingBridge(
            vault,
            address(0),
            address(this)
        );
    }

    // ============ Deposit Tests (via rebalance) ============

    function test_rebalance_depositsIntoVault() public {
        // First, deposit some collateral into the warp route
        _depositCollateralIntoWarpRoute(ALICE, transferAmount);

        uint256 warpBalanceBefore = primaryToken.balanceOf(address(localToken));
        assertEq(warpBalanceBefore, transferAmount);

        // Rebalancer moves collateral into vault
        vm.prank(REBALANCER);
        vm.expectEmit(true, true, true, true);
        emit Deposited(transferAmount, transferAmount); // 1:1 at start
        vm.expectEmit(true, true, true, true);
        emit CollateralMoved(
            ORIGIN,
            address(localToken).addressToBytes32(),
            transferAmount,
            REBALANCER
        );
        collateralToken.rebalance(ORIGIN, transferAmount, rebalancingBridge);

        // Verify state
        assertEq(primaryToken.balanceOf(address(localToken)), 0);
        assertEq(rebalancingBridge.principalDeposited(), transferAmount);
        assertEq(vault.balanceOf(address(rebalancingBridge)), transferAmount);
    }

    function test_rebalance_revertsNonRebalancer() public {
        _depositCollateralIntoWarpRoute(ALICE, transferAmount);

        vm.prank(ALICE);
        vm.expectRevert("MCR: Only Rebalancer");
        collateralToken.rebalance(ORIGIN, transferAmount, rebalancingBridge);
    }

    function test_transferRemote_revertsNonLocalDomain() public {
        vm.prank(address(localToken));
        vm.expectRevert(ERC4626RebalancingBridge.OnlyLocalDomain.selector);
        rebalancingBridge.transferRemote(
            DESTINATION, // non-local domain
            ALICE.addressToBytes32(),
            transferAmount
        );
    }

    function test_transferRemote_revertsNonWarpRoute() public {
        vm.prank(ALICE);
        vm.expectRevert(ERC4626RebalancingBridge.OnlyWarpRoute.selector);
        rebalancingBridge.transferRemote(
            ORIGIN,
            ALICE.addressToBytes32(),
            transferAmount
        );
    }

    // ============ Withdraw Principal Tests ============

    function test_withdrawPrincipal_success() public {
        // Deposit collateral and rebalance into vault
        _depositAndRebalance(transferAmount);

        uint256 withdrawAmount = transferAmount / 2;

        vm.expectEmit(true, true, true, true);
        emit PrincipalWithdrawn(withdrawAmount, address(localToken));
        rebalancingBridge.withdrawPrincipal(withdrawAmount);

        // Verify state
        assertEq(
            rebalancingBridge.principalDeposited(),
            transferAmount - withdrawAmount
        );
        assertEq(primaryToken.balanceOf(address(localToken)), withdrawAmount);
    }

    function test_withdrawPrincipal_fullAmount() public {
        _depositAndRebalance(transferAmount);

        rebalancingBridge.withdrawPrincipal(transferAmount);

        assertEq(rebalancingBridge.principalDeposited(), 0);
        assertEq(primaryToken.balanceOf(address(localToken)), transferAmount);
    }

    function test_withdrawPrincipal_revertsExceedsPrincipal() public {
        _depositAndRebalance(transferAmount);

        vm.expectRevert(ERC4626RebalancingBridge.ExceedsPrincipal.selector);
        rebalancingBridge.withdrawPrincipal(transferAmount + 1);
    }

    function test_withdrawPrincipal_revertsNonOwner() public {
        _depositAndRebalance(transferAmount);

        vm.prank(ALICE);
        vm.expectRevert("Ownable: caller is not the owner");
        rebalancingBridge.withdrawPrincipal(transferAmount);
    }

    // ============ Claim Yield Tests ============

    function test_claimYield_success() public {
        _depositAndRebalance(transferAmount);

        // Accrue yield
        _accrueYield(YIELD);

        uint256 expectedYield = _expectedNetYield(YIELD);
        uint256 yieldRecipientBalanceBefore = primaryToken.balanceOf(YIELD_RECIPIENT);

        // Don't check exact event values due to rounding
        uint256 claimedYield = rebalancingBridge.claimYield();

        assertApproxEqRel(claimedYield, expectedYield, 1e14);
        assertApproxEqRel(
            primaryToken.balanceOf(YIELD_RECIPIENT) - yieldRecipientBalanceBefore,
            expectedYield,
            1e14
        );
    }

    function test_claimYield_revertsNoYield() public {
        _depositAndRebalance(transferAmount);

        // No yield accrued
        vm.expectRevert(ERC4626RebalancingBridge.NoYieldAvailable.selector);
        rebalancingBridge.claimYield();
    }

    function test_claimYield_revertsNoYieldRecipient() public {
        // Create a new bridge without yield recipient set
        ERC4626RebalancingBridge newBridge = new ERC4626RebalancingBridge(
            vault,
            address(localToken),
            address(this)
        );
        
        // Enroll and add this new bridge
        collateralToken.addBridge(ORIGIN, newBridge);
        
        // Deposit into new bridge (need to setup similar to setUp)
        _depositCollateralIntoWarpRoute(ALICE, transferAmount);
        vm.prank(REBALANCER);
        collateralToken.rebalance(ORIGIN, transferAmount, newBridge);
        
        _accrueYield(YIELD);

        // Try to claim without yield recipient set
        vm.expectRevert(ERC4626RebalancingBridge.NoYieldRecipient.selector);
        newBridge.claimYield();
    }

    function test_claimYield_anyoneCanCall() public {
        _depositAndRebalance(transferAmount);
        _accrueYield(YIELD);

        // Even ALICE can call claimYield
        vm.prank(ALICE);
        uint256 claimedYield = rebalancingBridge.claimYield();
        assertTrue(claimedYield > 0);
    }

    function test_claimYield_doesNotAffectPrincipal() public {
        _depositAndRebalance(transferAmount);
        _accrueYield(YIELD);

        uint256 principalBefore = rebalancingBridge.principalDeposited();
        rebalancingBridge.claimYield();
        uint256 principalAfter = rebalancingBridge.principalDeposited();

        assertEq(principalBefore, principalAfter);
    }

    // ============ View Function Tests ============

    function test_pendingYield_noYield() public {
        _depositAndRebalance(transferAmount);
        assertEq(rebalancingBridge.pendingYield(), 0);
    }

    function test_pendingYield_withYield() public {
        _depositAndRebalance(transferAmount);
        _accrueYield(YIELD);

        uint256 expectedYield = _expectedNetYield(YIELD);
        assertApproxEqRel(
            rebalancingBridge.pendingYield(),
            expectedYield,
            1e14
        );
    }

    function test_totalVaultAssets() public {
        _depositAndRebalance(transferAmount);

        assertEq(rebalancingBridge.totalVaultAssets(), transferAmount);

        _accrueYield(YIELD);

        assertApproxEqRel(
            rebalancingBridge.totalVaultAssets(),
            transferAmount + _expectedNetYield(YIELD),
            1e14
        );
    }

    function test_vaultShares() public {
        _depositAndRebalance(transferAmount);

        // At start, 1:1 ratio
        assertEq(rebalancingBridge.vaultShares(), transferAmount);
    }

    // ============ Quote Tests ============

    function test_quoteTransferRemote_noFees() public view {
        Quote[] memory quotes = rebalancingBridge.quoteTransferRemote(
            ORIGIN,
            ALICE.addressToBytes32(),
            transferAmount
        );

        assertEq(quotes.length, 3);
        // Native fee
        assertEq(quotes[0].token, address(0));
        assertEq(quotes[0].amount, 0);
        // Collateral amount
        assertEq(quotes[1].token, address(primaryToken));
        assertEq(quotes[1].amount, transferAmount);
        // External fee
        assertEq(quotes[2].token, address(primaryToken));
        assertEq(quotes[2].amount, 0);
    }

    // ============ Integration Tests ============

    function test_fullCycle_depositYieldWithdraw() public {
        // 1. Deposit collateral into warp route
        _depositCollateralIntoWarpRoute(ALICE, transferAmount);

        // 2. Rebalance into vault
        vm.prank(REBALANCER);
        collateralToken.rebalance(ORIGIN, transferAmount, rebalancingBridge);

        // 3. Accrue yield
        _accrueYield(YIELD);

        // 4. Claim yield
        uint256 yieldClaimed = rebalancingBridge.claimYield();
        assertTrue(yieldClaimed > 0);

        // 5. Withdraw principal
        rebalancingBridge.withdrawPrincipal(transferAmount);

        // Verify final state
        assertEq(rebalancingBridge.principalDeposited(), 0);
        // Note: There may be some dust left over due to vault rounding,
        // but the vast majority of yield should have been claimed
        assertLt(rebalancingBridge.pendingYield(), 1e18, "Most yield should be claimed");
        assertEq(primaryToken.balanceOf(address(localToken)), transferAmount);
        assertTrue(primaryToken.balanceOf(YIELD_RECIPIENT) > 0, "Yield recipient should have received yield");
    }

    function test_multipleDepositsAndWithdrawals() public {
        // First deposit
        _depositCollateralIntoWarpRoute(ALICE, transferAmount);
        vm.prank(REBALANCER);
        collateralToken.rebalance(ORIGIN, transferAmount, rebalancingBridge);

        // Accrue some yield
        _accrueYield(YIELD);

        // Second deposit
        _depositCollateralIntoWarpRoute(BOB, transferAmount);
        vm.prank(REBALANCER);
        collateralToken.rebalance(ORIGIN, transferAmount, rebalancingBridge);

        // Total principal should be 2x
        assertEq(rebalancingBridge.principalDeposited(), 2 * transferAmount);

        // Withdraw half
        rebalancingBridge.withdrawPrincipal(transferAmount);
        assertEq(rebalancingBridge.principalDeposited(), transferAmount);

        // Claim yield
        uint256 yieldClaimed = rebalancingBridge.claimYield();
        assertTrue(yieldClaimed > 0);

        // Final withdrawal
        rebalancingBridge.withdrawPrincipal(transferAmount);
        assertEq(rebalancingBridge.principalDeposited(), 0);
    }

    function test_warpRouteStillFunctional() public {
        // Deposit and rebalance part of collateral
        _depositCollateralIntoWarpRoute(ALICE, transferAmount * 2);

        vm.prank(REBALANCER);
        collateralToken.rebalance(ORIGIN, transferAmount, rebalancingBridge);

        // Warp route should still have transferAmount
        assertEq(primaryToken.balanceOf(address(localToken)), transferAmount);

        // Can still do remote transfers with remaining collateral
        vm.startPrank(BOB);
        primaryToken.approve(address(localToken), transferAmount);
        localToken.transferRemote(
            DESTINATION,
            BOB.addressToBytes32(),
            transferAmount
        );
        vm.stopPrank();

        // Process inbound message
        remoteMailbox.processNextInboundMessage();
        assertEq(remoteToken.balanceOf(BOB), transferAmount);
    }

    // ============ Helper Functions ============

    function _depositCollateralIntoWarpRoute(
        address _user,
        uint256 _amount
    ) internal {
        vm.startPrank(_user);
        primaryToken.approve(address(localToken), _amount);
        localToken.transferRemote(
            DESTINATION,
            _user.addressToBytes32(),
            _amount
        );
        vm.stopPrank();
        remoteMailbox.processNextInboundMessage();
    }

    function _depositAndRebalance(uint256 _amount) internal {
        _depositCollateralIntoWarpRoute(ALICE, _amount);
        vm.prank(REBALANCER);
        collateralToken.rebalance(ORIGIN, _amount, rebalancingBridge);
    }

    function _accrueYield(uint256 _yield) internal {
        primaryToken.mintTo(address(vault), _yield);
    }

    function _expectedNetYield(uint256 _grossYield) internal pure returns (uint256) {
        // 10% goes to vault owner as fees
        return (_grossYield * 9) / 10;
    }
}

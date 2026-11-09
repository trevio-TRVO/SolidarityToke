// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title TokenSale
/// @notice Fixed-price USDC sale of TRVO. No owner, no pause, no admin withdrawal.
/// Price: 10,000 USDC / 4,200,000 TRVO = 420 TRVO per USDC.
/// USDC has 6 decimals and TRVO 18, so tokens = usdcUnits * 420e12 (exact, no division).
/// Buyers: 25% claimable at TGE (= finalize time), 75% linear over 180 days.
/// Refunds are permissionless if the soft cap is missed at saleEnd.
/// The per-wallet cap is a weak anti-concentration signal, not an AML control.
contract TokenSale is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant SOFT_CAP = 5_000e6;
    uint256 public constant HARD_CAP = 10_000e6;
    uint256 public constant MAX_PER_WALLET = 500e6;
    uint256 public constant TOKENS_FOR_SALE = 4_200_000e18;
    uint256 public constant USDC_FOR_LIQUIDITY = 5_000e6;
    uint256 public constant PRICE_MULTIPLIER = 420e12; // TRVO wei per USDC unit
    uint256 public constant TGE_UNLOCK_BPS = 2500;
    uint256 public constant BPS = 10_000;
    uint256 public constant VESTING_DURATION = 180 days;

    IERC20 public immutable usdc;
    IERC20 public immutable trvo;
    /// @notice Receives unsold TRVO (Treasury VestingWallet).
    address public immutable treasuryVesting;
    /// @notice Receives USDC raised above USDC_FOR_LIQUIDITY (immutable multisig).
    address public immutable fundsRecipient;
    /// @notice Receives USDC_FOR_LIQUIDITY (liquidity provisioner, to be defined).
    address public immutable liquidityReceiver;
    uint256 public immutable saleStart;
    uint256 public immutable saleEnd;

    uint256 public totalRaised;
    uint256 public totalSold;
    bool public finalized;
    uint256 public tgeTime;

    mapping(address => uint256) public contributed;
    mapping(address => uint256) public purchased;
    mapping(address => uint256) public claimed;
    mapping(address => bool) public refunded;

    event Purchased(address indexed buyer, uint256 usdcAmount, uint256 trvoAmount);
    event Finalized(uint256 raised, uint256 sold, uint256 unsoldToTreasury, uint256 tgeTime);
    event Refunded(address indexed buyer, uint256 usdcAmount);
    event Claimed(address indexed buyer, uint256 amount);
    event FailedSaleTokensRecovered(uint256 amount);

    constructor(
        IERC20 usdc_,
        IERC20 trvo_,
        address treasuryVesting_,
        address fundsRecipient_,
        address liquidityReceiver_,
        uint256 saleStart_,
        uint256 saleEnd_
    ) {
        require(address(usdc_) != address(0) && address(trvo_) != address(0), "token=0");
        require(
            treasuryVesting_ != address(0) && fundsRecipient_ != address(0)
                && liquidityReceiver_ != address(0),
            "addr=0"
        );
        require(saleStart_ >= block.timestamp && saleEnd_ > saleStart_, "bad dates");
        usdc = usdc_;
        trvo = trvo_;
        treasuryVesting = treasuryVesting_;
        fundsRecipient = fundsRecipient_;
        liquidityReceiver = liquidityReceiver_;
        saleStart = saleStart_;
        saleEnd = saleEnd_;
    }

    function buy(uint256 usdcAmount) external nonReentrant {
        require(block.timestamp >= saleStart && block.timestamp < saleEnd, "not open");
        require(!finalized, "finalized");
        require(usdcAmount > 0, "amount=0");
        require(totalRaised + usdcAmount <= HARD_CAP, "hard cap");
        require(contributed[msg.sender] + usdcAmount <= MAX_PER_WALLET, "wallet cap");

        uint256 tokens = usdcAmount * PRICE_MULTIPLIER;
        totalRaised += usdcAmount;
        totalSold += tokens;
        contributed[msg.sender] += usdcAmount;
        purchased[msg.sender] += tokens;

        usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);
        emit Purchased(msg.sender, usdcAmount, tokens);
    }

    /// @notice Permissionless. Allowed once the sale ended (or hard cap reached) with soft cap met.
    function finalize() external nonReentrant {
        require(!finalized, "finalized");
        require(block.timestamp >= saleEnd || totalRaised == HARD_CAP, "not ended");
        require(totalRaised >= SOFT_CAP, "soft cap missed");
        require(trvo.balanceOf(address(this)) >= TOKENS_FOR_SALE, "sale underfunded");

        finalized = true;
        tgeTime = block.timestamp;

        uint256 unsold = TOKENS_FOR_SALE - totalSold;
        uint256 surplus = totalRaised - USDC_FOR_LIQUIDITY;

        if (unsold > 0) trvo.safeTransfer(treasuryVesting, unsold);
        usdc.safeTransfer(liquidityReceiver, USDC_FOR_LIQUIDITY);
        if (surplus > 0) usdc.safeTransfer(fundsRecipient, surplus);

        emit Finalized(totalRaised, totalSold, unsold, tgeTime);
    }

    function saleFailed() public view returns (bool) {
        return !finalized && block.timestamp >= saleEnd && totalRaised < SOFT_CAP;
    }

    /// @notice Permissionless per buyer. 100% of USDC returned if the soft cap was missed.
    function refund() external nonReentrant {
        require(saleFailed(), "no refund");
        require(!refunded[msg.sender], "already refunded");
        uint256 amount = contributed[msg.sender];
        require(amount > 0, "nothing");
        refunded[msg.sender] = true;
        usdc.safeTransfer(msg.sender, amount);
        emit Refunded(msg.sender, amount);
    }

    /// @notice Permissionless. If the sale failed, TRVO held here goes to the Treasury vesting.
    function recoverFailedSaleTokens() external nonReentrant {
        require(saleFailed(), "not failed");
        uint256 bal = trvo.balanceOf(address(this));
        require(bal > 0, "nothing");
        trvo.safeTransfer(treasuryVesting, bal);
        emit FailedSaleTokensRecovered(bal);
    }

    function vested(address buyer) public view returns (uint256) {
        if (!finalized) return 0;
        uint256 total = purchased[buyer];
        uint256 tge = (total * TGE_UNLOCK_BPS) / BPS;
        uint256 linear = total - tge;
        uint256 elapsed = block.timestamp - tgeTime;
        if (elapsed > VESTING_DURATION) elapsed = VESTING_DURATION;
        return tge + (linear * elapsed) / VESTING_DURATION;
    }

    function claimable(address buyer) public view returns (uint256) {
        return vested(buyer) - claimed[buyer];
    }

    function claim() external nonReentrant {
        uint256 amount = claimable(msg.sender);
        require(amount > 0, "nothing");
        claimed[msg.sender] += amount;
        trvo.safeTransfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }
}

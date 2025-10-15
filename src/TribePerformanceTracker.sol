// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { TribeCopyVault } from "./TribeCopyVault.sol";
import { TribeVaultFactory } from "./TribeVaultFactory.sol";
import { TribeLeaderRegistry } from "./TribeLeaderRegistry.sol";

/**
 * @title TribePerformanceTracker
 * @notice Tracks and calculates performance metrics for leaders and vaults
 * @dev Uses Chainlink price feeds for accurate USD calculations and APR metrics
 */
contract TribePerformanceTracker is Ownable {
    
    TribeVaultFactory public immutable VAULT_FACTORY;
    TribeLeaderRegistry public immutable LEADER_REGISTRY;
    
    // Token => Chainlink Price Feed
    mapping(address => address) public priceFeeds;
    
    // Performance metrics
    struct PerformanceMetrics {
        uint256 totalFeesEarned; // in USD (18 decimals)
        uint256 netApr; // basis points (e.g., 1250 = 12.50%)
        uint256 totalVolume; // in USD
        uint256 maxDrawdown; // basis points
        uint256 riskScore; // 0-100
        uint256 lastUpdated;
    }
    
    // Leader => Performance Metrics
    mapping(address => PerformanceMetrics) public leaderMetrics;
    
    // Vault => Performance Metrics
    mapping(address => PerformanceMetrics) public vaultMetrics;
    
    // Historical snapshots for APR calculation
    struct Snapshot {
        uint256 timestamp;
        uint256 totalValue; // in USD
        uint256 feesCollected; // in USD
    }
    
    mapping(address => Snapshot[]) public leaderSnapshots;
    mapping(address => Snapshot[]) public vaultSnapshots;
    
    // Constants
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    uint256 public constant BASIS_POINTS = 10000;
    
    // Events
    event PriceFeedUpdated(address indexed token, address indexed priceFeed);
    event MetricsUpdated(address indexed entity, uint256 netApr, uint256 totalFeesEarned);
    event SnapshotRecorded(address indexed entity, uint256 totalValue, uint256 timestamp);
    
    constructor(
        address _vaultFactory,
        address _leaderRegistry
    ) Ownable(msg.sender) {
        require(_vaultFactory != address(0), "Invalid factory");
        require(_leaderRegistry != address(0), "Invalid registry");
        
        VAULT_FACTORY = TribeVaultFactory(_vaultFactory);
        LEADER_REGISTRY = TribeLeaderRegistry(_leaderRegistry);
    }
    
    /**
     * @notice Set Chainlink price feed for a token
     */
    function setPriceFeed(address token, address priceFeed) external onlyOwner {
        require(token != address(0), "Invalid token");
        require(priceFeed != address(0), "Invalid price feed");
        
        priceFeeds[token] = priceFeed;
        emit PriceFeedUpdated(token, priceFeed);
    }
    
    /**
     * @notice Get USD price for a token using Chainlink
     */
    function getTokenPriceUsd(address token) public view returns (uint256) {
        address priceFeed = priceFeeds[token];
        require(priceFeed != address(0), "Price feed not set");
        
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeed);
        (, int256 price,,,) = feed.latestRoundData();
        require(price > 0, "Invalid price");
        
        uint8 decimals = feed.decimals();
        
        // Normalize to 18 decimals
        if (decimals < 18) {
            return uint256(price) * (10 ** (18 - decimals));
        } else if (decimals > 18) {
            return uint256(price) / (10 ** (decimals - 18));
        }
        
        return uint256(price);
    }
    
    /**
     * @notice Calculate USD value of a token amount
     */
    function calculateUsdValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getTokenPriceUsd(token);
        return (amount * price) / 1e18;
    }
    
    /**
     * @notice Record a snapshot for performance tracking
     */
    function recordSnapshot(
        address entity,
        uint256 totalValue,
        uint256 feesCollected,
        bool isVault
    ) external {
        // In production, restrict to authorized contracts
        
        Snapshot memory snapshot = Snapshot({
            timestamp: block.timestamp,
            totalValue: totalValue,
            feesCollected: feesCollected
        });
        
        if (isVault) {
            vaultSnapshots[entity].push(snapshot);
        } else {
            leaderSnapshots[entity].push(snapshot);
        }
        
        emit SnapshotRecorded(entity, totalValue, block.timestamp);
    }
    
    /**
     * @notice Calculate APR for a leader based on historical data
     * @dev APR = (Total Fees Earned / Average Capital) * (365 days / Time Period) * 100
     */
    function calculateLeaderApr(address leader) public view returns (uint256) {
        Snapshot[] memory snapshots = leaderSnapshots[leader];
        
        if (snapshots.length < 2) return 0;
        
        Snapshot memory first = snapshots[0];
        Snapshot memory last = snapshots[snapshots.length - 1];
        
        uint256 timePeriod = last.timestamp - first.timestamp;
        if (timePeriod == 0) return 0;
        
        uint256 totalFees = last.feesCollected - first.feesCollected;
        uint256 averageCapital = (first.totalValue + last.totalValue) / 2;
        
        if (averageCapital == 0) return 0;
        
        // APR = (totalFees / averageCapital) * (SECONDS_PER_YEAR / timePeriod) * BASIS_POINTS
        uint256 apr = (totalFees * SECONDS_PER_YEAR * BASIS_POINTS) / (averageCapital * timePeriod);
        
        return apr;
    }
    
    /**
     * @notice Calculate APR for a specific vault
     */
    function calculateVaultApr(address vault) public view returns (uint256) {
        Snapshot[] memory snapshots = vaultSnapshots[vault];
        
        if (snapshots.length < 2) return 0;
        
        Snapshot memory first = snapshots[0];
        Snapshot memory last = snapshots[snapshots.length - 1];
        
        uint256 timePeriod = last.timestamp - first.timestamp;
        if (timePeriod == 0) return 0;
        
        uint256 totalFees = last.feesCollected - first.feesCollected;
        uint256 averageCapital = (first.totalValue + last.totalValue) / 2;
        
        if (averageCapital == 0) return 0;
        
        uint256 apr = (totalFees * SECONDS_PER_YEAR * BASIS_POINTS) / (averageCapital * timePeriod);
        
        return apr;
    }
    
    /**
     * @notice Calculate 30-day APR for a leader
     */
    function calculate30DayApr(address leader) public view returns (uint256) {
        Snapshot[] memory snapshots = leaderSnapshots[leader];
        
        if (snapshots.length == 0) return 0;
        
        uint256 cutoffTime = block.timestamp - 30 days;
        uint256 startIndex = 0;
        
        // Find first snapshot within 30 days
        for (uint256 i = snapshots.length; i > 0; i--) {
            if (snapshots[i - 1].timestamp <= cutoffTime) {
                startIndex = i;
                break;
            }
        }
        
        if (startIndex >= snapshots.length - 1) return 0;
        
        Snapshot memory first = snapshots[startIndex];
        Snapshot memory last = snapshots[snapshots.length - 1];
        
        uint256 timePeriod = last.timestamp - first.timestamp;
        if (timePeriod == 0) return 0;
        
        uint256 totalFees = last.feesCollected - first.feesCollected;
        uint256 averageCapital = (first.totalValue + last.totalValue) / 2;
        
        if (averageCapital == 0) return 0;
        
        uint256 apr = (totalFees * SECONDS_PER_YEAR * BASIS_POINTS) / (averageCapital * timePeriod);
        
        return apr;
    }
    
    /**
     * @notice Calculate maximum drawdown for a leader
     */
    function calculateMaxDrawdown(address leader) public view returns (uint256) {
        Snapshot[] memory snapshots = leaderSnapshots[leader];
        
        if (snapshots.length < 2) return 0;
        
        uint256 peak = 0;
        uint256 maxDrawdown = 0;
        
        for (uint256 i = 0; i < snapshots.length; i++) {
            uint256 value = snapshots[i].totalValue;
            
            if (value > peak) {
                peak = value;
            } else if (peak > 0) {
                uint256 drawdown = ((peak - value) * BASIS_POINTS) / peak;
                if (drawdown > maxDrawdown) {
                    maxDrawdown = drawdown;
                }
            }
        }
        
        return maxDrawdown;
    }
    
    /**
     * @notice Calculate risk score based on volatility
     */
    function calculateRiskScore(address leader) public view returns (uint256) {
        Snapshot[] memory snapshots = leaderSnapshots[leader];
        
        if (snapshots.length < 3) return 50; // Default medium risk
        
        // Calculate standard deviation of returns
        uint256 sum = 0;
        uint256 count = snapshots.length - 1;
        
        for (uint256 i = 1; i < snapshots.length; i++) {
            if (snapshots[i - 1].totalValue > 0) {
                uint256 return_ = ((snapshots[i].totalValue * BASIS_POINTS) / snapshots[i - 1].totalValue);
                sum += return_;
            }
        }
        
        uint256 avgReturn = sum / count;
        uint256 variance = 0;
        
        for (uint256 i = 1; i < snapshots.length; i++) {
            if (snapshots[i - 1].totalValue > 0) {
                uint256 return_ = ((snapshots[i].totalValue * BASIS_POINTS) / snapshots[i - 1].totalValue);
                uint256 diff = return_ > avgReturn ? return_ - avgReturn : avgReturn - return_;
                variance += diff * diff;
            }
        }
        
        variance = variance / count;
        
        // Convert variance to risk score (0-100)
        // Higher variance = higher risk
        uint256 riskScore = (variance / 100); // Simplified calculation
        
        return riskScore > 100 ? 100 : riskScore;
    }
    
    /**
     * @notice Update all metrics for a leader
     */
    function updateLeaderMetrics(address leader) external {
        require(LEADER_REGISTRY.isRegisteredLeader(leader), "Not a leader");
        
        uint256 apr = calculateLeaderApr(leader);
        uint256 maxDrawdown = calculateMaxDrawdown(leader);
        uint256 riskScore = calculateRiskScore(leader);
        
        Snapshot[] memory snapshots = leaderSnapshots[leader];
        uint256 totalFees = snapshots.length > 0 ? snapshots[snapshots.length - 1].feesCollected : 0;
        uint256 totalVolume = snapshots.length > 0 ? snapshots[snapshots.length - 1].totalValue : 0;
        
        leaderMetrics[leader] = PerformanceMetrics({
            totalFeesEarned: totalFees,
            netApr: apr,
            totalVolume: totalVolume,
            maxDrawdown: maxDrawdown,
            riskScore: riskScore,
            lastUpdated: block.timestamp
        });
        
        emit MetricsUpdated(leader, apr, totalFees);
    }
    
    /**
     * @notice Get leader metrics
     */
    function getLeaderMetrics(address leader) external view returns (PerformanceMetrics memory) {
        return leaderMetrics[leader];
    }
    
    /**
     * @notice Get vault metrics
     */
    function getVaultMetrics(address vault) external view returns (PerformanceMetrics memory) {
        return vaultMetrics[vault];
    }
    
    /**
     * @notice Get leader snapshots
     */
    function getLeaderSnapshots(address leader) external view returns (Snapshot[] memory) {
        return leaderSnapshots[leader];
    }
    
    /**
     * @notice Get vault snapshots
     */
    function getVaultSnapshots(address vault) external view returns (Snapshot[] memory) {
        return vaultSnapshots[vault];
    }
    
    /**
     * @notice Compare vault APR vs simple HODL
     */
    function compareVsHodl(
        address vault,
        address token
    ) external view returns (int256 difference) {
        uint256 vaultApr = calculateVaultApr(vault);
        
        // Get HODL performance (just price appreciation)
        Snapshot[] memory snapshots = vaultSnapshots[vault];
        if (snapshots.length < 2) return 0;
        
        uint256 initialPrice = getTokenPriceUsd(token);
        uint256 currentPrice = getTokenPriceUsd(token);
        
        uint256 timePeriod = snapshots[snapshots.length - 1].timestamp - snapshots[0].timestamp;
        if (timePeriod == 0) return 0;
        
        uint256 priceAppreciation = ((currentPrice - initialPrice) * BASIS_POINTS) / initialPrice;
        uint256 hodlApr = (priceAppreciation * SECONDS_PER_YEAR) / timePeriod;
        
        return int256(vaultApr) - int256(hodlApr);
    }
}
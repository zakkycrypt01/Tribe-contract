// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { TribeLeaderRegistry } from "./TribeLeaderRegistry.sol";
import { TribePerformanceTracker } from "./TribePerformanceTracker.sol";
import { TribeVaultFactory } from "./TribeVaultFactory.sol";

/**
 * @title TribeLeaderboard
 * @notice Public interface for discovering and filtering leader strategies
 * @dev Provides ranking, filtering, and discovery functionality
 */
contract TribeLeaderboard is Ownable {
    
    TribeLeaderRegistry public immutable LEADER_REGISTRY;
    TribePerformanceTracker public immutable PERFORMANCE_TRACKER;
    TribeVaultFactory public immutable VAULT_FACTORY;
    
    // Risk levels
    enum RiskLevel {
        LOW,      // 0-30 risk score
        MEDIUM,   // 31-60 risk score
        HIGH      // 61-100 risk score
    }
    
    // Ranking criteria
    enum RankingCriteria {
        NET_APR,
        TOTAL_FEES,
        TOTAL_TVL,  // keeping enum values in CAPS as they are constants
        RISK_ADJUSTED_RETURN,
        FOLLOWER_COUNT
    }
    
    struct LeaderProfile {
        address wallet;
        string strategyName;
        string description;
        uint256 netApr;
        uint256 totalFeesEarned;
        uint256 totalTvl;
        uint256 riskScore;
        uint256 maxDrawdown;
        uint256 totalFollowers;
        uint16 performanceFeePercent;
        bool isActive;
        uint256 registrationTime;
    }
    
    // Token pair filter
    struct TokenPair {
        address token0;
        address token1;
    }
    
    // Events
    event LeaderRankingUpdated(address indexed leader, uint256 rank);
    
    constructor(
        address _leaderRegistry,
        address _performanceTracker,
        address _vaultFactory
    ) Ownable(msg.sender) {
        require(_leaderRegistry != address(0), "Invalid registry");
        require(_performanceTracker != address(0), "Invalid tracker");
        require(_vaultFactory != address(0), "Invalid factory");
        
        LEADER_REGISTRY = TribeLeaderRegistry(_leaderRegistry);
        PERFORMANCE_TRACKER = TribePerformanceTracker(_performanceTracker);
        VAULT_FACTORY = TribeVaultFactory(_vaultFactory);
    }
    
    /**
     * @notice Get detailed profile for a leader
     */
    function getLeaderProfile(address leader) public view returns (LeaderProfile memory) {
        require(LEADER_REGISTRY.isRegisteredLeader(leader), "Not a registered leader");
        
        TribeLeaderRegistry.Leader memory leaderData = LEADER_REGISTRY.getLeader(leader);
        TribePerformanceTracker.PerformanceMetrics memory metrics = 
            PERFORMANCE_TRACKER.getLeaderMetrics(leader);
        
        return LeaderProfile({
            wallet: leader,
            strategyName: leaderData.strategyName,
            description: leaderData.description,
            netApr: metrics.netApr,
            totalFeesEarned: metrics.totalFeesEarned,
            totalTvl: leaderData.totalTvl,
            riskScore: metrics.riskScore,
            maxDrawdown: metrics.maxDrawdown,
            totalFollowers: leaderData.totalFollowers,
            performanceFeePercent: leaderData.performanceFeePercent,
            isActive: leaderData.isActive,
            registrationTime: leaderData.registrationTime
        });
    }
    
    /**
     * @notice Get all leader profiles
     */
    function getAllLeaderProfiles() external view returns (LeaderProfile[] memory) {
        address[] memory allLeaders = LEADER_REGISTRY.getAllLeaders();
        LeaderProfile[] memory profiles = new LeaderProfile[](allLeaders.length);
        
        for (uint256 i = 0; i < allLeaders.length; i++) {
            profiles[i] = getLeaderProfile(allLeaders[i]);
        }
        
        return profiles;
    }
    
    /**
     * @notice Get top leaders by specific criteria
     */
    function getTopLeaders(
        RankingCriteria criteria,
        uint256 limit
    ) external view returns (LeaderProfile[] memory) {
        address[] memory allLeaders = LEADER_REGISTRY.getAllLeaders();
        
        // Get all active leaders
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allLeaders.length; i++) {
            TribeLeaderRegistry.Leader memory leader = LEADER_REGISTRY.getLeader(allLeaders[i]);
            if (leader.isActive) activeCount++;
        }
        
        LeaderProfile[] memory activeProfiles = new LeaderProfile[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allLeaders.length; i++) {
            TribeLeaderRegistry.Leader memory leader = LEADER_REGISTRY.getLeader(allLeaders[i]);
            if (leader.isActive) {
                activeProfiles[index] = getLeaderProfile(allLeaders[i]);
                index++;
            }
        }
        
        // Sort by criteria
        _sortLeaders(activeProfiles, criteria);
        
        // Return top N
        uint256 returnCount = limit > activeProfiles.length ? activeProfiles.length : limit;
        LeaderProfile[] memory topLeaders = new LeaderProfile[](returnCount);
        
        for (uint256 i = 0; i < returnCount; i++) {
            topLeaders[i] = activeProfiles[i];
        }
        
        return topLeaders;
    }
    
    /**
     * @notice Filter leaders by risk level
     */
    function filterByRiskLevel(RiskLevel riskLevel) external view returns (LeaderProfile[] memory) {
        address[] memory allLeaders = LEADER_REGISTRY.getAllLeaders();
        
        // First pass: count matching leaders
        uint256 matchCount = 0;
        for (uint256 i = 0; i < allLeaders.length; i++) {
            LeaderProfile memory profile = getLeaderProfile(allLeaders[i]);
            if (!profile.isActive) continue;
            
            if (_matchesRiskLevel(profile.riskScore, riskLevel)) {
                matchCount++;
            }
        }
        
        // Second pass: populate array
        LeaderProfile[] memory filtered = new LeaderProfile[](matchCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allLeaders.length; i++) {
            LeaderProfile memory profile = getLeaderProfile(allLeaders[i]);
            if (!profile.isActive) continue;
            
            if (_matchesRiskLevel(profile.riskScore, riskLevel)) {
                filtered[index] = profile;
                index++;
            }
        }
        
        return filtered;
    }
    
    /**
     * @notice Filter leaders by token pair (simplified - would need more complex implementation)
     */
    function filterByTokenPair(
        address /* token0 */,
        address /* token1 */
    ) external view returns (LeaderProfile[] memory) {
        address[] memory allLeaders = LEADER_REGISTRY.getAllLeaders();
        
        // Note: In production, this would query position data to match token pairs
        // For now, returning all active leaders as placeholder
        
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allLeaders.length; i++) {
            TribeLeaderRegistry.Leader memory leader = LEADER_REGISTRY.getLeader(allLeaders[i]);
            if (leader.isActive) activeCount++;
        }
        
        LeaderProfile[] memory filtered = new LeaderProfile[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allLeaders.length; i++) {
            TribeLeaderRegistry.Leader memory leader = LEADER_REGISTRY.getLeader(allLeaders[i]);
            if (leader.isActive) {
                filtered[index] = getLeaderProfile(allLeaders[i]);
                index++;
            }
        }
        
        return filtered;
    }
    
    /**
     * @notice Filter leaders by protocol (Uniswap V3 or Aerodrome)
     */
    function filterByProtocol(address /* protocol */) external view returns (LeaderProfile[] memory) {
        address[] memory allLeaders = LEADER_REGISTRY.getAllLeaders();
        
        // Note: In production, this would query position data to match protocols
        // Placeholder implementation
        
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allLeaders.length; i++) {
            TribeLeaderRegistry.Leader memory leader = LEADER_REGISTRY.getLeader(allLeaders[i]);
            if (leader.isActive) activeCount++;
        }
        
        LeaderProfile[] memory filtered = new LeaderProfile[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allLeaders.length; i++) {
            TribeLeaderRegistry.Leader memory leader = LEADER_REGISTRY.getLeader(allLeaders[i]);
            if (leader.isActive) {
                filtered[index] = getLeaderProfile(allLeaders[i]);
                index++;
            }
        }
        
        return filtered;
    }
    
    /**
     * @notice Get leaders with minimum APR threshold
     */
    function filterByMinApr(uint256 minApr) external view returns (LeaderProfile[] memory) {
        address[] memory allLeaders = LEADER_REGISTRY.getAllLeaders();
        
        uint256 matchCount = 0;
        for (uint256 i = 0; i < allLeaders.length; i++) {
            LeaderProfile memory profile = getLeaderProfile(allLeaders[i]);
            if (profile.isActive && profile.netApr >= minApr) {
                matchCount++;
            }
        }
        
        LeaderProfile[] memory filtered = new LeaderProfile[](matchCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allLeaders.length; i++) {
            LeaderProfile memory profile = getLeaderProfile(allLeaders[i]);
            if (profile.isActive && profile.netApr >= minApr) {
                filtered[index] = profile;
                index++;
            }
        }
        
        return filtered;
    }
    
    /**
     * @notice Calculate risk-adjusted return (Sharpe-like ratio)
     */
    function calculateRiskAdjustedReturn(address leader) public view returns (uint256) {
        TribePerformanceTracker.PerformanceMetrics memory metrics = 
            PERFORMANCE_TRACKER.getLeaderMetrics(leader);
        
        if (metrics.riskScore == 0) return metrics.netApr;
        
        // Risk-adjusted return = APR / (Risk Score / 100)
        // This gives higher scores to strategies with better risk-adjusted returns
        return (metrics.netApr * 100) / metrics.riskScore;
    }
    
    /**
     * @notice Get leader statistics summary
     */
    function getLeaderStats(address leader) external view returns (
        uint256 apr30Day,
        uint256 totalApr,
        uint256 maxDrawdown,
        uint256 riskScore,
        uint256 sharpeRatio,
        uint256 totalFollowers,
        uint256 totalTvl
    ) {
        apr30Day = PERFORMANCE_TRACKER.calculate30DayApr(leader);
        
        TribePerformanceTracker.PerformanceMetrics memory metrics = 
            PERFORMANCE_TRACKER.getLeaderMetrics(leader);
        
        totalApr = metrics.netApr;
        maxDrawdown = metrics.maxDrawdown;
        riskScore = metrics.riskScore;
        sharpeRatio = calculateRiskAdjustedReturn(leader);
        
        TribeLeaderRegistry.Leader memory leaderData = LEADER_REGISTRY.getLeader(leader);
        totalFollowers = leaderData.totalFollowers;
        totalTvl = leaderData.totalTvl;
    }
    
    /**
     * @notice Check if risk score matches risk level
     */
    function _matchesRiskLevel(uint256 riskScore, RiskLevel level) internal pure returns (bool) {
        if (level == RiskLevel.LOW) {
            return riskScore <= 30;
        } else if (level == RiskLevel.MEDIUM) {
            return riskScore > 30 && riskScore <= 60;
        } else {
            return riskScore > 60;
        }
    }
    
    /**
     * @notice Sort leaders by criteria (bubble sort for simplicity)
     */
    function _sortLeaders(
        LeaderProfile[] memory profiles,
        RankingCriteria criteria
    ) internal pure {
        uint256 n = profiles.length;
        
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                bool shouldSwap = false;
                
                if (criteria == RankingCriteria.NET_APR) {
                    shouldSwap = profiles[j].netApr < profiles[j + 1].netApr;
                } else if (criteria == RankingCriteria.TOTAL_FEES) {
                    shouldSwap = profiles[j].totalFeesEarned < profiles[j + 1].totalFeesEarned;
                } else if (criteria == RankingCriteria.TOTAL_TVL) {
                    shouldSwap = profiles[j].totalTvl < profiles[j + 1].totalTvl;
                } else if (criteria == RankingCriteria.FOLLOWER_COUNT) {
                    shouldSwap = profiles[j].totalFollowers < profiles[j + 1].totalFollowers;
                } else if (criteria == RankingCriteria.RISK_ADJUSTED_RETURN) {
                    uint256 rarJ = profiles[j].riskScore > 0 ? 
                        (profiles[j].netApr * 100) / profiles[j].riskScore : profiles[j].netApr;
                    uint256 rarJPlus1 = profiles[j + 1].riskScore > 0 ? 
                        (profiles[j + 1].netApr * 100) / profiles[j + 1].riskScore : profiles[j + 1].netApr;
                    shouldSwap = rarJ < rarJPlus1;
                }
                
                if (shouldSwap) {
                    LeaderProfile memory temp = profiles[j];
                    profiles[j] = profiles[j + 1];
                    profiles[j + 1] = temp;
                }
            }
        }
    }
}
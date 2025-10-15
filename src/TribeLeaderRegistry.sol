// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {TribeCopyVault} from "./TribeCopyVault.sol";

/**
 * @title TribeLeaderRegistry
 * @notice Manages Leader registration, qualification, and strategy metadata
 * @dev Implements the 80% profitability gate using historical LP position data
 */
contract TribeLeaderRegistry is Ownable, ReentrancyGuard {
    struct Leader {
        address wallet;
        string strategyName;
        string description;
        bool isActive;
        uint256 registrationTime;
        uint256 totalFollowers;
        uint256 totalTvl;
        uint16 performanceFeePercent; // basis points (e.g., 1000 = 10%)
    }

    struct HistoricalPosition {
        address token0;
        address token1;
        uint256 openTime;
        uint256 closeTime;
        uint256 principalUsd;
        int256 netPnLUsd; // Can be negative
        bool isProfitable;
    }

    // Leader wallet => Leader data
    mapping(address => Leader) public leaders;

    // Leader wallet => array of historical positions
    mapping(address => HistoricalPosition[]) public leaderHistory;

    // Leader wallet => is registered
    mapping(address => bool) public isRegisteredLeader;

    // Array of all leader addresses
    address[] public allLeaders;

    // Constants
    uint256 public constant MIN_PROFITABILITY_PERCENT = 80; // 80%
    uint256 public constant MIN_HISTORICAL_POSITIONS = 5; // Minimum positions to qualify
    uint16 public constant MAX_PERFORMANCE_FEE = 2000; // 20% max

    // Events
    event LeaderRegistered(address indexed leader, string strategyName, uint16 performanceFee);
    event LeaderDeactivated(address indexed leader);
    event LeaderReactivated(address indexed leader);
    event StrategyUpdated(address indexed leader, string newName, string newDescription);
    event HistoricalPositionAdded(address indexed leader, bool isProfitable);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Submit historical LP positions for qualification
     * @param positions Array of historical positions with PnL data
     */
    function submitHistoricalPositions(HistoricalPosition[] calldata positions) external {
        require(positions.length >= MIN_HISTORICAL_POSITIONS, "Insufficient position history");
        require(!isRegisteredLeader[msg.sender], "Already registered");

        uint256 profitableCount = 0;

        for (uint256 i = 0; i < positions.length; i++) {
            require(positions[i].closeTime > positions[i].openTime, "Invalid position times");
            require(positions[i].closeTime <= block.timestamp, "Future close time");

            leaderHistory[msg.sender].push(positions[i]);

            if (positions[i].isProfitable) {
                profitableCount++;
            }

            emit HistoricalPositionAdded(msg.sender, positions[i].isProfitable);
        }

        uint256 profitabilityPercent = (profitableCount * 100) / positions.length;
        require(profitabilityPercent >= MIN_PROFITABILITY_PERCENT, "Does not meet 80% profitability requirement");
    }

    /**
     * @notice Register as a Leader after passing qualification
     * @param strategyName Public name for the strategy
     * @param description Strategy description
     * @param performanceFeePercent Performance fee in basis points (max 2000 = 20%)
     */
    function registerAsLeader(string calldata strategyName, string calldata description, uint16 performanceFeePercent)
        external
        nonReentrant
    {
        require(!isRegisteredLeader[msg.sender], "Already registered");
        require(leaderHistory[msg.sender].length >= MIN_HISTORICAL_POSITIONS, "Must submit historical positions first");
        require(bytes(strategyName).length > 0, "Strategy name required");
        require(performanceFeePercent <= MAX_PERFORMANCE_FEE, "Fee too high");

        leaders[msg.sender] = Leader({
            wallet: msg.sender,
            strategyName: strategyName,
            description: description,
            isActive: true,
            registrationTime: block.timestamp,
            totalFollowers: 0,
            totalTvl: 0,
            performanceFeePercent: performanceFeePercent
        });

        isRegisteredLeader[msg.sender] = true;
        allLeaders.push(msg.sender);

        emit LeaderRegistered(msg.sender, strategyName, performanceFeePercent);
    }

    /**
     * @notice Update strategy metadata
     */
    function updateStrategy(string calldata newName, string calldata newDescription) external {
        require(isRegisteredLeader[msg.sender], "Not a registered leader");
        require(bytes(newName).length > 0, "Strategy name required");

        leaders[msg.sender].strategyName = newName;
        leaders[msg.sender].description = newDescription;

        emit StrategyUpdated(msg.sender, newName, newDescription);
    }

    /**
     * @notice Deactivate a leader strategy
     */
    function deactivateLeader(address leader) external onlyOwner {
        require(isRegisteredLeader[leader], "Not a registered leader");
        leaders[leader].isActive = false;
        emit LeaderDeactivated(leader);
    }

    /**
     * @notice Reactivate a leader strategy
     */
    function reactivateLeader(address leader) external onlyOwner {
        require(isRegisteredLeader[leader], "Not a registered leader");
        leaders[leader].isActive = true;
        emit LeaderReactivated(leader);
    }

    /**
     * @notice Update follower count and TVL (called by vault factory)
     */
    function updateLeaderMetrics(address leader, uint256 followerCount, uint256 tvl) external {
        // In production, restrict this to authorized contracts only
        require(isRegisteredLeader[leader], "Not a registered leader");
        leaders[leader].totalFollowers = followerCount;
        leaders[leader].totalTvl = tvl;
    }

    /**
     * @notice Get leader details
     */
    function getLeader(address leader) external view returns (Leader memory) {
        require(isRegisteredLeader[leader], "Not a registered leader");
        return leaders[leader];
    }

    /**
     * @notice Get all leader addresses
     */
    function getAllLeaders() external view returns (address[] memory) {
        return allLeaders;
    }

    /**
     * @notice Get historical positions for a leader
     */
    function getLeaderHistory(address leader) external view returns (HistoricalPosition[] memory) {
        return leaderHistory[leader];
    }

    /**
     * @notice Calculate profitability percentage for a leader
     */
    function calculateProfitability(address leader) external view returns (uint256) {
        HistoricalPosition[] memory positions = leaderHistory[leader];
        if (positions.length == 0) return 0;

        uint256 profitableCount = 0;
        for (uint256 i = 0; i < positions.length; i++) {
            if (positions[i].isProfitable) {
                profitableCount++;
            }
        }

        return (profitableCount * 100) / positions.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TribeCopyVault
 * @notice Individual vault that holds follower assets and mirrors leader actions
 * @dev Each follower has their own dedicated vault that proportionally copies leader trades
 */
contract TribeCopyVault is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    
    // Vault metadata
    address public immutable FOLLOWER;
    address public immutable LEADER;
    address public immutable TERMINAL; // Leader Terminal contract
    
    // Performance tracking
    uint256 public depositedCapital;
    uint256 public highWaterMark;
    uint16 public performanceFeePercent; // basis points
    
    // Position tracking
    struct Position {
        address protocol; // Uniswap V3 or Aerodrome
        address token0;
        address token1;
        uint256 liquidity;
        uint256 tokenId; // For Uniswap V3 NFT positions
        bool isActive;
    }
    
    Position[] public positions;
    mapping(uint256 => bool) public activePositions;
    
    // Withdrawal tracking
    bool public emergencyMode;
    uint256 public lastActivityTime;
    
    // Events
    event Deposited(address indexed follower, uint256 amount);
    event Withdrawn(address indexed follower, uint256 amount, uint256 performanceFee);
    event PositionMirrored(address indexed protocol, address token0, address token1, uint256 liquidity);
    event PositionClosed(uint256 indexed positionId);
    event EmergencyModeActivated(address indexed follower);
    event PerformanceFeeCollected(address indexed leader, uint256 amount);
    
    modifier onlyFollower() {
        require(msg.sender == FOLLOWER, "Only follower");
        _;
    }
    
    modifier onlyTerminal() {
        require(msg.sender == TERMINAL, "Only terminal");
        _;
    }
    
    constructor(
        address _follower,
        address _leader,
        address _terminal,
        uint16 _performanceFeePercent
    ) Ownable(msg.sender) {
        require(_follower != address(0), "Invalid follower");
        require(_leader != address(0), "Invalid leader");
        require(_terminal != address(0), "Invalid terminal");
        require(_performanceFeePercent <= 2000, "Fee too high"); // Max 20%
        
        FOLLOWER = _follower;
        LEADER = _leader;
        TERMINAL = _terminal;
        performanceFeePercent = _performanceFeePercent;
        lastActivityTime = block.timestamp;
    }
    
    /**
     * @notice Deposit capital into the vault
     */
    function deposit(address token, uint256 amount) external onlyFollower nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(!emergencyMode, "Emergency mode active");
        
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            require(msg.sender == FOLLOWER, "Only follower");
        
        if (highWaterMark == 0) {
            highWaterMark = depositedCapital;
        }
        
        lastActivityTime = block.timestamp;
            require(msg.sender == TERMINAL, "Only terminal");
    }
    
    /**
     * @notice Withdraw capital and realized profits
     */
    function withdraw(address token, uint256 amount) external onlyFollower nonReentrant {
        require(amount > 0, "Amount must be > 0");
        
        uint256 vaultBalance = IERC20(token).balanceOf(address(this));
        require(vaultBalance >= amount, "Insufficient balance");
        
        // Calculate performance fee if above high water mark
        uint256 performanceFee = 0;
        if (vaultBalance > highWaterMark) {
            uint256 profit = vaultBalance - highWaterMark;
            performanceFee = (profit * performanceFeePercent) / 10000;
            
            // Transfer fee to leader
            if (performanceFee > 0) {
                IERC20(token).safeTransfer(LEADER, performanceFee);
                emit PerformanceFeeCollected(LEADER, performanceFee);
            }
            
            // Update high water mark
            highWaterMark = vaultBalance - performanceFee;
        }
        
        // Transfer to follower
        uint256 followerAmount = amount - performanceFee;
        IERC20(token).safeTransfer(FOLLOWER, followerAmount);
        
        depositedCapital = depositedCapital > followerAmount ? depositedCapital - followerAmount : 0;
        lastActivityTime = block.timestamp;
        
        emit Withdrawn(FOLLOWER, followerAmount, performanceFee);
    }
    
    /**
     * @notice Mirror a leader's LP action (called by Terminal during leader transaction)
     * @param protocol The DEX protocol (Uniswap V3 or Aerodrome)
     * @param token0 First token in the pair
     * @param token1 Second token in the pair
     */
    function mirrorPosition(
        address protocol,
        address token0,
        address token1,
        uint256 liquidity,
        bytes calldata /* data */
    ) external onlyTerminal nonReentrant returns (uint256 positionId) {
        require(!emergencyMode, "Emergency mode active");
        // Create new position record
        positionId = positions.length;
        positions.push(Position({
            protocol: protocol,
            token0: token0,
            token1: token1,
            liquidity: liquidity,
            tokenId: 0, // Will be set for Uniswap V3
            isActive: true
        }));
        activePositions[positionId] = true;
        lastActivityTime = block.timestamp;
        emit PositionMirrored(protocol, token0, token1, liquidity);
        return positionId;
    }
    
    /**
     * @notice Mirror closing a position
     */
    function mirrorClosePosition(
        uint256 positionId
    ) external onlyTerminal nonReentrant {
        require(activePositions[positionId], "Position not active");
        
        positions[positionId].isActive = false;
        activePositions[positionId] = false;
        lastActivityTime = block.timestamp;
        
        emit PositionClosed(positionId);
    }
    
    /**
     * @notice Mirror a rebalance action
     */
    function mirrorRebalance(
        uint256 positionId,
        uint256 newLiquidity,
        bytes calldata /* data */
    ) external onlyTerminal nonReentrant {
        require(activePositions[positionId], "Position not active");
        
        positions[positionId].liquidity = newLiquidity;
        lastActivityTime = block.timestamp;
    }
    
    /**
     * @notice Activate emergency mode - allows follower to withdraw even if strategy underwater
     */
    function activateEmergencyMode() external onlyFollower {
        emergencyMode = true;
        emit EmergencyModeActivated(FOLLOWER);
    }
    
    /**
     * @notice Emergency withdrawal (no performance fee)
     */
    function emergencyWithdraw(address token) external onlyFollower nonReentrant {
        require(emergencyMode, "Emergency mode not active");
        
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(FOLLOWER, balance);
            emit Withdrawn(FOLLOWER, balance, 0);
        }
    }
    
    /**
     * @notice Get vault value
     */
    function getVaultValue(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
    
    /**
     * @notice Get all positions
     */
    function getAllPositions() external view returns (Position[] memory) {
        return positions;
    }
    
    /**
     * @notice Get active position count
     */
    function getActivePositionCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < positions.length; i++) {
            if (activePositions[i]) {
                count++;
            }
        }
        return count;
    }
    
    /**
     * @notice Calculate current profit/loss
     */
    function calculatePnL(address token) external view returns (int256) {
        uint256 currentValue = IERC20(token).balanceOf(address(this));
        return int256(currentValue) - int256(depositedCapital);
    }
}
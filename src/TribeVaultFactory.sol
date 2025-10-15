// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { TribeCopyVault } from "./TribeCopyVault.sol";
import { TribeLeaderRegistry } from "./TribeLeaderRegistry.sol";

/**
 * @title TribeVaultFactory
 * @notice Factory contract for creating and managing follower copy vaults
 * @dev Creates individual vaults for each follower-leader pair
 */
contract TribeVaultFactory is Ownable, ReentrancyGuard {
    
    TribeLeaderRegistry public immutable LEADER_REGISTRY;
    address public Terminal;
    
    // Follower => Leader => Vault
    mapping(address => mapping(address => address)) public followerVaults;
    
    // Leader => array of follower vaults
    mapping(address => address[]) public leaderFollowerVaults;
    
    // All vaults
    address[] public allVaults;
    
    // Vault => is valid
    mapping(address => bool) public isValidVault;
    
    // Events
    event VaultCreated(
        address indexed follower,
        address indexed leader,
        address vault,
        uint16 performanceFee
    );
    event TerminalUpdated(address indexed oldTerminal, address indexed newTerminal);
    
    constructor(address _leaderRegistry) Ownable(msg.sender) {
        require(_leaderRegistry != address(0), "Invalid registry");
        LEADER_REGISTRY = TribeLeaderRegistry(_leaderRegistry);
    }
    
    /**
     * @notice Set the Leader Terminal contract address
     */
    function setTerminal(address _terminal) external onlyOwner {
        require(_terminal != address(0), "Invalid terminal");
        address oldTerminal = Terminal;
        Terminal = _terminal;
        emit TerminalUpdated(oldTerminal, _terminal);
    }
    
    /**
     * @notice Create a new copy vault for a follower
     * @param leader Address of the leader to copy
     * @return vault Address of the newly created vault
     */
    function createVault(address leader) external nonReentrant returns (address vault) {
        require(Terminal != address(0), "Terminal not set");
        require(LEADER_REGISTRY.isRegisteredLeader(leader), "Leader not registered");
        require(followerVaults[msg.sender][leader] == address(0), "Vault already exists");
        
        // Get leader's performance fee
        TribeLeaderRegistry.Leader memory leaderData = LEADER_REGISTRY.getLeader(leader);
        require(leaderData.isActive, "Leader not active");
        
        // Deploy new vault
        TribeCopyVault newVault = new TribeCopyVault(
            msg.sender,
            leader,
            Terminal,
            leaderData.performanceFeePercent
        );
        
        vault = address(newVault);
        
        // Store vault mappings
        followerVaults[msg.sender][leader] = vault;
        leaderFollowerVaults[leader].push(vault);
        allVaults.push(vault);
        isValidVault[vault] = true;
        
        emit VaultCreated(msg.sender, leader, vault, leaderData.performanceFeePercent);
        
        return vault;
    }
    
    /**
     * @notice Get vault address for a follower-leader pair
     */
    function getVault(address follower, address leader) external view returns (address) {
        return followerVaults[follower][leader];
    }
    
    /**
     * @notice Get all follower vaults for a specific leader
     */
    function getLeaderVaults(address leader) external view returns (address[] memory) {
        return leaderFollowerVaults[leader];
    }
    
    /**
     * @notice Get total follower count for a leader
     */
    function getLeaderFollowerCount(address leader) external view returns (uint256) {
        return leaderFollowerVaults[leader].length;
    }
    
    /**
     * @notice Get all vaults in the system
     */
    function getAllVaults() external view returns (address[] memory) {
        return allVaults;
    }
    
    /**
     * @notice Calculate total tvl for a leader across all follower vaults
     */
    function getLeaderTvl(address leader, address token) external view returns (uint256 totalTvl) {
        address[] memory vaults = leaderFollowerVaults[leader];
        
        for (uint256 i = 0; i < vaults.length; i++) {
            TribeCopyVault vault = TribeCopyVault(vaults[i]);
            totalTvl += vault.getVaultValue(token);
        }
        
        return totalTvl;
    }
    
    /**
     * @notice Check if an address is a valid vault
     */
    function isVault(address _vault) external view returns (bool) {
        return isValidVault[_vault];
    }
}
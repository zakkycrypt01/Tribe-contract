import { createPublicClient, createWalletClient, http, parseAbi, formatEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { baseSepolia } from 'viem/chains';
import * as dotenv from 'dotenv';

dotenv.config();

// Contract addresses
const VAULT_FACTORY = '0xdEc456e502CB9baB4a33153206a470B65Bedcf9E';
const USDC = '0x036CbD53842c5426634e7929541eC2318f3dCF7e';
const WETH = '0x4200000000000000000000000000000000000006';

// ABIs
const vaultFactoryAbi = parseAbi([
    'function getVault(address leader, address follower) view returns (address)',
    'function createVault(address leader) returns (address)',
]);

const vaultAbi = parseAbi([
    'function deposit(address token, uint256 amount) returns (bool)',
    'function depositedCapital() view returns (uint256)',
    'function highWaterMark() view returns (uint256)',
    'function getActivePositionCount() view returns (uint256)',
    'function getAllPositions() view returns ((address,address,address,uint256,uint256,bool)[])',
]);

const erc20Abi = parseAbi([
    'function balanceOf(address account) view returns (uint256)',
    'function approve(address spender, uint256 amount) returns (bool)',
]);

async function main() {
    // Setup clients
    const publicClient = createPublicClient({
        chain: baseSepolia,
        transport: http()
    });

    const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
    
    const walletClient = createWalletClient({
        account,
        chain: baseSepolia,
        transport: http()
    });

    console.log('Using wallet address:', account.address);

    try {
        // Step 1: Get vault for user following themselves
        console.log('\n--- Step 1: Get Follower Vault ---');
        
        const vaultAddress = await publicClient.readContract({
            address: VAULT_FACTORY,
            abi: vaultFactoryAbi,
            functionName: 'getVault',
            args: [account.address, account.address],
        }) as `0x${string}`;

        if (vaultAddress === '0x0000000000000000000000000000000000000000') {
            console.log('Creating new vault...');
            const hash = await walletClient.writeContract({
                address: VAULT_FACTORY,
                abi: vaultFactoryAbi,
                functionName: 'createVault',
                args: [account.address],
            });
            
            await publicClient.waitForTransactionReceipt({ hash });
            console.log('New vault created:', vaultAddress);
        } else {
            console.log('Existing vault found:', vaultAddress);
        }

        // Step 2: Check balances
        console.log('\n--- Step 2: Check Balances ---');
        
        const usdcBalance = await publicClient.readContract({
            address: USDC,
            abi: erc20Abi,
            functionName: 'balanceOf',
            args: [account.address],
        });

        const wethBalance = await publicClient.readContract({
            address: WETH,
            abi: erc20Abi,
            functionName: 'balanceOf',
            args: [account.address],
        });

        console.log('USDC Balance:', usdcBalance.toString());
        console.log('WETH Balance:', formatEther(wethBalance), 'WETH');

        // Define deposit amounts
        const depositAmountUSDC = 2n; // 2 raw USDC units
        const depositAmountWETH = 50000000000000n; // 0.00005 WETH

        // Step 3: Deposit tokens
        console.log('\n--- Step 3: Deposit Tokens ---');
        
        if (usdcBalance >= depositAmountUSDC) {
            console.log('Approving USDC...');
            const approveHash = await walletClient.writeContract({
                address: USDC,
                abi: erc20Abi,
                functionName: 'approve',
                args: [vaultAddress, depositAmountUSDC],
            });
            await publicClient.waitForTransactionReceipt({ hash: approveHash });
            
            console.log('Depositing USDC...');
            const depositHash = await walletClient.writeContract({
                address: vaultAddress,
                abi: vaultAbi,
                functionName: 'deposit',
                args: [USDC, depositAmountUSDC],
            });
            await publicClient.waitForTransactionReceipt({ hash: depositHash });
            console.log('Deposited', depositAmountUSDC.toString(), 'USDC');
        } else {
            console.log('Insufficient USDC balance');
        }

        if (wethBalance >= depositAmountWETH) {
            console.log('Approving WETH...');
            const approveHash = await walletClient.writeContract({
                address: WETH,
                abi: erc20Abi,
                functionName: 'approve',
                args: [vaultAddress, depositAmountWETH],
            });
            await publicClient.waitForTransactionReceipt({ hash: approveHash });
            
            console.log('Depositing WETH...');
            const depositHash = await walletClient.writeContract({
                address: vaultAddress,
                abi: vaultAbi,
                functionName: 'deposit',
                args: [WETH, depositAmountWETH],
            });
            await publicClient.waitForTransactionReceipt({ hash: depositHash });
            console.log('Deposited', formatEther(depositAmountWETH), 'WETH');
        } else {
            console.log('Insufficient WETH balance');
        }

        // Step 4: Check vault state
        console.log('\n--- Step 4: Vault State ---');
        
        const vaultCapital = await publicClient.readContract({
            address: vaultAddress,
            abi: vaultAbi,
            functionName: 'depositedCapital',
        }) as bigint;

        const vaultHWM = await publicClient.readContract({
            address: vaultAddress,
            abi: vaultAbi,
            functionName: 'highWaterMark',
        }) as bigint;

        const activePositions = await publicClient.readContract({
            address: vaultAddress,
            abi: vaultAbi,
            functionName: 'getActivePositionCount',
        }) as bigint;

        console.log('Vault Deposited Capital:', vaultCapital.toString());
        console.log('Vault High Water Mark:', vaultHWM.toString());
        console.log('Active Positions:', activePositions.toString());

        if (activePositions > 0) {
            console.log('\n--- Active Positions Details ---');
            const rawPositions = await publicClient.readContract({
                address: vaultAddress,
                abi: vaultAbi,
                functionName: 'getAllPositions',
            }) as [`0x${string}`, `0x${string}`, `0x${string}`, bigint, bigint, boolean][];

            rawPositions.forEach((pos, index) => {
                console.log(`Position ${index + 1}:`);
                console.log('  Protocol:', pos[0]);
                console.log('  Token0:', pos[1]);
                console.log('  Token1:', pos[2]);
                console.log('  Liquidity:', pos[3].toString());
                console.log('  Token ID:', pos[4].toString());
                console.log('  Is Active:', pos[5]);
            });
        }

    } catch (error) {
        console.error('Error:', error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
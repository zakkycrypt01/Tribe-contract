
import { ethers } from "ethers";
import ABIS from "../abis/index";

const provider = new ethers.JsonRpcProvider("YOUR_RPC_URL");
const contractAddress = "0x8b1192C386A778EBD27AB0317b81d1D9DB00CccA";

async function main() {
  const signer = await provider.getSigner();
  const adapter = new ethers.Contract(contractAddress, ABIS.TribeUniswapV3Adapter, signer);

  // Example mintPosition call
  const tx = await adapter.mintPosition(
    "0xToken0", // token0 address
    "0xToken1", // token1 address
    3000,        // fee
    -887220,     // tickLower
    887220,      // tickUpper
    ethers.parseUnits("1.0", 18), // amount0Desired
    ethers.parseUnits("1.0", 18), // amount1Desired
    0,           // amount0Min
    0,           // amount1Min
    "0xRecipient" // recipient address
  );
  const receipt = await tx.wait();
  // Get tokenId from the returned values
  const [tokenId, liquidity, amount0, amount1] = receipt.logs.length
    ? adapter.interface.decodeFunctionResult("mintPosition", receipt.logs[0].data)
    : [null, null, null, null];
  console.log("Minted position:", { tokenId, liquidity, amount0, amount1 });

  // Fetch position info
  if (tokenId) {
    const positionInfo = await adapter.getPositionInfo(tokenId);
    console.log("Position Info:", positionInfo);
  } else {
    console.log("TokenId not found in logs. Check contract events or receipt.");
  }
}

main().catch(console.error);

// This file exports and links all contract ABIs for use in TypeScript
import TribeVaultFactory from '../out/TribeVaultFactory.sol/TribeVaultFactory.json';
import TribePerformanceTracker from '../out/TribePerformanceTracker.sol/TribePerformanceTracker.json';
import TribeUniswapV3Adapter from '../out/TribeUniswapV3Adapter.sol/TribeUniswapV3Adapter.json';
import TribeAerodromeAdapter from '../out/TribeAerodromeAdapter.sol/TribeAerodromeAdapter.json';

export const ABIS = {
  TribeVaultFactory: TribeVaultFactory.abi,
  TribePerformanceTracker: TribePerformanceTracker.abi,
  TribeUniswapV3Adapter: TribeUniswapV3Adapter.abi,
  TribeAerodromeAdapter: TribeAerodromeAdapter.abi,
};

export default ABIS;

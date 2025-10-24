// This file exports and links all contract ABIs for use in TypeScript projects

import TribeVaultFactory from '../out/TribeVaultFactory.sol/TribeVaultFactory.json';
import TribePerformanceTracker from '../out/TribePerformanceTracker.sol/TribePerformanceTracker.json';
import TribeUniswapV3Adapter from '../out/TribeUniswapV3Adapter.sol/TribeUniswapV3Adapter.json';

export const ABIS = {
  TribeVaultFactory: TribeVaultFactory.abi,
  TribePerformanceTracker: TribePerformanceTracker.abi,
  TribeUniswapV3Adapter: TribeUniswapV3Adapter.abi,
};

export const BYTECODES = {
  TribeVaultFactory: TribeVaultFactory.bytecode?.object,
  TribePerformanceTracker: TribePerformanceTracker.bytecode?.object,
  TribeUniswapV3Adapter: TribeUniswapV3Adapter.bytecode?.object,
};

export default {
  ABIS,
  BYTECODES,
};

import hre, { ethers } from "hardhat";

export const advanceBlocks = async (blockNumber: number) => {
  while (blockNumber > 0) {
    blockNumber--;
    await ethers.provider.send("evm_mine", []);
  }
};

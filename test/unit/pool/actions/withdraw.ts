import { expect } from "chai";
import hre, { ethers } from "hardhat";

import { hardcap, listingRate, presaleRate, types, value, vesting } from "../../../../constants";
import { Errors } from "../../../shared/errors";

export const advanceBlocks = async (blockNumber: number) => {
  while (blockNumber > 0) {
    blockNumber--;
    await ethers.provider.send("evm_mine", []);
  }
};
export default function shouldBehaveLikeWithdraw(): void {
  context("withdraw", function () {
    it("Should properly create presale", async function () {
      const domain = {
        name: "EIP712-Derive",
        version: "1",
        chainId: 31337, //Hardhat mainnet-fork chain id
        verifyingContract: await this.contracts.poolManager.getAddress(),
      };
      const deployer = await this.contracts.poolManager.owner();
      const wallet = await hre.ethers.getSigner(deployer);
      const signature = await wallet.signTypedData(domain, types, {
        ...value,
        currency: await this.contracts.mockERC20.getAddress(),
      });
      await this.contracts.pool.initialize(await this.contracts.poolManager.getAddress());
      await expect(
        this.contracts.pool.initialize(await this.contracts.poolManager.getAddress())
      ).to.be.revertedWithCustomError(this.contracts.pool, Errors.Pool_AlreadyInitialized);
      const usersTokenAmount = hardcap * BigInt(presaleRate); // Convert presaleRate to a bigint
      const liquidityTokenAmount = hardcap * BigInt(listingRate);
      const totalTokenAmount = usersTokenAmount + liquidityTokenAmount;
      // Create presale
      await this.contracts.poolManager.connect(wallet).createPresale(
        {
          ...value,
          currency: await this.contracts.mockERC20.getAddress(),
        },
        vesting,
        signature
      );
      const proxyAddress = await this.contracts.poolManager.presales(0);
      const poolBalance = await this.contracts.mockERC20.balanceOf(proxyAddress);
      expect(poolBalance.toString()).to.equal(totalTokenAmount.toString());
    });
    it("Should not contribute before start time", async function () {
      // const snapshot = await hre.network.provider.send("evm_snapshot");
      // const proxyAddress = await this.contracts.poolManager.presales(0);
      const snapshot = await hre.network.provider.send("evm_snapshot");
      // accumulate interest
      // await advanceBlocks(1000);
      const domain = {
        name: "EIP712-Derive",
        version: "1",
        chainId: 31337, //Hardhat mainnet-fork chain id
        verifyingContract: await this.contracts.poolManager.getAddress(),
      };
      const deployer = await this.contracts.poolManager.owner();
      const wallet = await hre.ethers.getSigner(deployer);
      const signature = await wallet.signTypedData(domain, types, {
        ...value,
        currency: await this.contracts.mockERC20.getAddress(),
      });
      await this.contracts.pool.initialize(await this.contracts.poolManager.getAddress());
      await expect(
        this.contracts.pool.initialize(await this.contracts.poolManager.getAddress())
      ).to.be.revertedWithCustomError(this.contracts.pool, Errors.Pool_AlreadyInitialized);
      const usersTokenAmount = hardcap * BigInt(presaleRate); // Convert presaleRate to a bigint
      const liquidityTokenAmount = hardcap * BigInt(listingRate);
      const totalTokenAmount = usersTokenAmount + liquidityTokenAmount;
      // Create presale
      await this.contracts.poolManager.connect(wallet).createPresale(
        {
          ...value,
          currency: await this.contracts.mockERC20.getAddress(),
        },
        vesting,
        signature
      );
      const proxyAddress = await this.contracts.poolManager.presales(0);
      const poolBalance = await this.contracts.mockERC20.balanceOf(proxyAddress);
      expect(poolBalance.toString()).to.equal(totalTokenAmount.toString());
      console.log(
        "poolBalance",
        poolBalance.toString(),
        "totalTokenAmount",
        totalTokenAmount.toString()
      );
      const proxy = await ethers.getContractAt("contracts/pools/Pool.sol:Pool", proxyAddress);
      const contributeAmount = ethers.parseEther("0.5");
      const [user1] = await ethers.getSigners();
      // accumulate interest
      await advanceBlocks(1000);
      await expect(proxy.connect(user1).contribute({ value: contributeAmount })).to.be.revertedWith(
        "The presale is not active at this time."
      );
    });
  });
}

import { expect } from "chai";
import hre, { ethers } from "hardhat";

import { hardcap, listingRate, presaleRate, types, value, vesting } from "../../../../constants";
import { advanceBlocks } from "../../../../utils/common";
import { Errors } from "../../../shared/errors";

const contributeAmount = ethers.parseEther("0.5");
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
      await hre.network.provider.send("evm_snapshot");
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
      const proxy = await ethers.getContractAt("contracts/pools/Pool.sol:Pool", proxyAddress);
      const [user1] = await ethers.getSigners();
      await advanceBlocks(1000);
      await expect(proxy.connect(user1).contribute({ value: contributeAmount })).to.be.revertedWith(
        "The presale is not active at this time."
      );
    });
    it("Should properly contribute", async function () {
      await hre.network.provider.send("evm_snapshot");
      const proxyAddress = await this.contracts.poolManager.presales(0);
      const proxy = await ethers.getContractAt("contracts/pools/Pool.sol:Pool", proxyAddress);
      await hre.network.provider.send("evm_increaseTime", [300]);
      await hre.network.provider.send("evm_mine");
      const signers = await ethers.getSigners();
      for (let i = 10; i < 20; i++) {
        const tempSigner = signers[i];
        await proxy.connect(tempSigner).contribute({ value: contributeAmount });
      }
    });
  });
}

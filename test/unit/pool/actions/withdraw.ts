import { expect } from "chai";
import hre from "hardhat";

import { hardcap, listingRate, presaleRate, types, value, vesting } from "../../../../constants";
import { Errors } from "../../../shared/errors";

export default function shouldBehaveLikeWithdraw(): void {
  context("withdraw", function () {
    it("Should properly create presale", async function () {
      // const snapshot = await hre.network.provider.send("evm_snapshot");
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

      console.log(
        await this.contracts.poolManager.getAddress(),
        await this.contracts.pool.getAddress()
      );
      // Create presale
      await this.contracts.poolManager.connect(wallet).createPresale(
        {
          ...value,
          currency: await this.contracts.mockERC20.getAddress(),
        },
        vesting,
        signature
      );
      // const proxyAddress = await this.contracts.poolManager.presales(0);
      // const proxy = await ethers.getContractAt("contracts/pools/Pool.sol:Pool", proxyAddress);
      // const poolBalance = await this.contracts.mockERC20.balanceOf(proxyAddress);
      // expect(poolBalance.toString()).to.equal(totalTokenAmount.toString());
    });
  });
}

import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

import { hardcap, listingRate, presaleRate, types, value, vesting } from "../../../../constants";
import { PoolManager } from "../../../../types";
import { proxy } from "../../../../types/@openzeppelin/contracts";
import { Errors } from "../../../shared/errors";
import { Pool } from "./../../../../types/contracts/pools/Pool";

export default function shouldBehaveLikeWithdraw(): void {
  context("withdraw", function () {
    it("Should properly create presale", async function () {
      const signers = await ethers.getSigners();
      const deployer: SignerWithAddress = signers[0];
      const domain = {
        name: "EIP712-Derive",
        version: "1",
        chainId: 31337, //Hardhat mainnet-fork chain id
        verifyingContract: await this.contracts.poolManager.getAddress(),
      };
      const wallet = ethers.Wallet.createRandom();
      await hre.network.provider.send("hardhat_impersonateAccount", [wallet.address]);
      const signer = await ethers.getSigner(wallet.address);
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
    });
  });
}

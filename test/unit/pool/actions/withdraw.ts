import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

import { Errors } from "../../../shared/errors";

export default function shouldBehaveLikeWithdraw(): void {
  context("when called too soon", function () {
    it("Should properly initialize ", async () => {
      const snapshot = await hre.network.provider.send("evm_snapshot");
      const signers = await ethers.getSigners();
      const deployer: SignerWithAddress = signers[0];
    });
    it("Should properly create presale", async () => {});
  });
}

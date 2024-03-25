import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import hre, { ethers } from "hardhat";



import { Errors } from "../../../shared/errors";
import { types, value } from "../../constants";

export default function shouldBehaveLikeWithdraw(): void {
  context("withdraw", function () {
    it("Should properly initialize ", async function () {
      const snapshot = await hre.network.provider.send("evm_snapshot");
      const signers = await ethers.getSigners();
      const deployer: SignerWithAddress = signers[0];
    });
    it("Should properly create presale", async function () {
      const signers = await ethers.getSigners();
      const deployer: SignerWithAddress = signers[0];
      const domain = {
        name: "EIP712-Derive",
        version: "1",
        chainId: 31337, //Hardhat mainnet-fork chain id
        verifyingContract: await this.contracts.poolManager.getAddress(),
      };
      // const wallet = new ethers.Wallet(process.env.PRIVATE_KEY as string);
      const wallet = ethers.Wallet.createRandom();
      await hre.network.provider.send("hardhat_impersonateAccount", [wallet.address]);
      const signer = await ethers.getSigner(wallet.address);
      // const signedMessage = await signer.signMessage("foo");
      const signature = await wallet.signTypedData(domain, types, {
        ...value,
        currency: await this.contracts.mockERC20.getAddress(),
      });
      console.log("Signature: ", signature);
      // await this.contracts.pool
      //   .connect(deployer)
      //   .initialize(await this.contracts.poolManager.getAddress());
      // const usersTokenAmount = hardcap * presaleRate;
      // const liquidityTokenAmount = hardcap * listingRate;
      // totalTokenAmount = usersTokenAmount + liquidityTokenAmount;
      // await expect(Pool.connect(deployers).initialize(PoolManager.address)).to.be.revertedWith(
      //   "Already initialized"
      // );
      // await PoolManager.connect(deployers).createPresale(value, vesting, signature);
      // const proxyAddress = await PoolManager.connect(deployers).presales(0);
      // proxy = await ethers.getContractAt("contracts/pools/Pool.sol:Pool", proxyAddress);
      // const poolBalance = await MockERC20Contract.connect(deployers).balanceOf(proxyAddress);
      // expect(poolBalance.toString()).to.equal(totalTokenAmount.toString());
    });
  });
}
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";



import { Errors } from "../../../shared/errors";

export default function shouldBehaveLikeWithdraw(): void {
  context("when called too soon", function () {
    it("reverts", async function () {
      // await expect(this.contracts.lock.withdraw()).to.be.revertedWithCustomError(
      //   this.contracts.lock,
      //   Errors.Lock_CannotWithdrawYet
      // );
    });
  });
}

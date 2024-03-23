import { shouldBehaveLikeLockContract } from "./Pool.behavior";
import { poolFixture } from "./Pool.fixture";


export function Pool(): void {
  describe("Pool", function () {
    beforeEach(async function () {
      const { pool, padLock, unlockTime, lockedAmount } = await this.loadFixture(poolFixture);
      console.log(poolFixture, "poolFixture");
      this.contracts.pool = pool;
      this.unlockTime = unlockTime;
      this.lockedAmount = lockedAmount;
    });
    shouldBehaveLikeLockContract();
  });
}
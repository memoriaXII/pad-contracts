import { shouldBehaveLikeLockContract } from "./Pool.behavior";
import { poolFixture } from "./Pool.fixture";

export function testLock(): void {
  describe("Lock", function () {
    beforeEach(async function () {
      const { lock, unlockTime, lockedAmount } = await this.loadFixture(poolFixture);
      this.contracts.lock = lock;
      this.unlockTime = unlockTime;
      this.lockedAmount = lockedAmount;
    });

    shouldBehaveLikeLockContract();
  });
}

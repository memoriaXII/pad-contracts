import { poolFixture } from "./fixtures/pool.fixture";

export function Pool(): void {
  describe("Pool", function () {
    beforeEach(async function () {
      const { pool, padLock, poolManager, unlockTime, lockedAmount } =
        await this.loadFixture(poolFixture);
      this.contracts.pool = pool;
      this.contracts.padLock = padLock;
      this.contracts.poolManager = poolManager;
      this.unlockTime = unlockTime;
      this.lockedAmount = lockedAmount;
    });
    // shouldBehaveLikeLockContract();
    describe("View Functions", function () {
      describe("# read initial parameters", function () {
        //shouldReadParameters();
      });
    });
    describe("Action Functions", function () {
      describe("#constructor", function () {});
      describe("#liqudiity", function () {
        //shouldBehaveAddLiquidity();
      });
    });
  });
}

import shouldBehaveLikeCreatePool from "./actions/withdraw";
import { poolFixture } from "./fixtures/pool.fixture";

export function Pool(): void {
  describe("Pool", function () {
    beforeEach(async function () {
      const { pool, padLock, poolManager, token } = await this.loadFixture(poolFixture);
      this.contracts.pool = pool;
      this.contracts.padLock = padLock;
      this.contracts.poolManager = poolManager;
      this.contracts.mockERC20 = token;
    });
    describe("View Functions", function () {
      describe("# read initial parameters", function () {});
    });
    describe("Action Functions", function () {
      describe("#Create Pool", function () {
        shouldBehaveLikeCreatePool();
      });
    });
  });
}

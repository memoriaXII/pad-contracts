import { network } from "hardhat";

import shouldBehaveLikeWithdraw from "./actions/withdraw";
import { poolFixture } from "./fixtures/pool.fixture";

export function Pool(): void {
  describe("Pool", function () {
    // beforeEach(async function () {
    //   const { pool, padLock, poolManager, token } = await this.loadFixture(poolFixture);
    //   this.contracts.pool = pool;
    //   this.contracts.padLock = padLock;
    //   this.contracts.poolManager = poolManager;
    //   this.contracts.mockERC20 = token;
    //   this.snapshotId = await network.provider.send("evm_snapshot");
    //   await network.provider.send("evm_increaseTime", [900]);
    //   await network.provider.send("evm_mine");
    // });
    // afterEach(async function () {
    //   await network.provider.send("evm_revert", [this.snapshotId]);
    // });

    // shouldBehaveLikeLockContract();
    describe("View Functions", function () {
      describe("# read initial parameters", function () {
        //shouldReadParameters();
      });
    });
    describe("Action Functions", function () {
      describe("#constructor", function () {
        shouldBehaveLikeWithdraw();
      });
      describe("#liqudiity", function () {
        //shouldBehaveAddLiquidity();
      });
    });
  });
}

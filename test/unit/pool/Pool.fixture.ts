import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";

import { PadLock__factory } from "../../../types";
import type { PadLock } from "../../../types/contracts/lock/PadLock";
import type { Pool } from "../../../types/contracts/pools/Pool";
import type { Pool__factory } from "../../../types/factories/contracts/pools/Pool__factory";

export async function poolFixture(): Promise<{
  pool: Pool;
  padLock: PadLock;
  unlockTime: number;
  lockedAmount: number;
}> {
  const signers = await ethers.getSigners();
  const deployer: SignerWithAddress = signers[0];

  const PoolFactory: Pool__factory = (await ethers.getContractFactory("Pool")) as Pool__factory;
  const PadLockFactory: PadLock__factory = (await ethers.getContractFactory(
    "PadLock"
  )) as PadLock__factory;

  const padLock: PadLock = (await PadLockFactory.connect(deployer).deploy()) as PadLock;
  await padLock.waitForDeployment();

  const ONE_YEAR_IN_SECS = time.duration.years(1);
  const ONE_GWEI = 1_000_000_000;

  const lockedAmount = ONE_GWEI;
  const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

  type DeployArgs = Parameters<typeof PoolFactory.deploy>;
  const args: DeployArgs = [padLock.getAddress()];

  const pool: Pool = (await PoolFactory.connect(deployer).deploy(...args)) as Pool;
  await pool.waitForDeployment();

  return { pool, padLock, unlockTime, lockedAmount };
}
import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";

import {
  MockERC20__factory,
  PadLock__factory,
  PoolManager,
  PoolManager__factory,
} from "../../../../types";
import type { PadLock } from "../../../../types/contracts/lock/PadLock";
import { MockERC20 } from "../../../../types/contracts/mocks/ERC20.sol/MockERC20";
import type { Pool } from "../../../../types/contracts/pools/Pool";
import type { Pool__factory } from "../../../../types/factories/contracts/pools/Pool__factory";

export async function poolFixture(): Promise<{
  pool: Pool;
  padLock: PadLock;
  poolManager: PoolManager;
  token: MockERC20;
}> {
  const tokenAmount = ethers.parseEther("100000000000000000");
  const signers = await ethers.getSigners();
  const deployer: SignerWithAddress = signers[0];

  const MockERC20Factory: MockERC20__factory = (await ethers.getContractFactory(
    "MockERC20"
  )) as MockERC20__factory;
  const PoolFactory: Pool__factory = (await ethers.getContractFactory("Pool")) as Pool__factory;
  const PoolManagerFactory: PoolManager__factory = (await ethers.getContractFactory(
    "PoolManager"
  )) as PoolManager__factory;
  const PadLockFactory: PadLock__factory = (await ethers.getContractFactory(
    "PadLock"
  )) as PadLock__factory;

  const token: MockERC20 = (await MockERC20Factory.connect(deployer).deploy()) as MockERC20;
  await token.waitForDeployment();

  const padLock: PadLock = (await PadLockFactory.connect(deployer).deploy()) as PadLock;
  await padLock.waitForDeployment();

  const poolManager: PoolManager = (await PoolManagerFactory.connect(deployer).deploy(
    deployer.address,
    await padLock.getAddress()
  )) as PoolManager;
  // PoolManager = await PoolManagerFactory.deploy(signerAddress, Pool.address);
  await poolManager.waitForDeployment();

  //token approval
  await token.connect(deployer).approve(poolManager.getAddress(), tokenAmount);

  const ONE_YEAR_IN_SECS = time.duration.years(1);
  const ONE_GWEI = 1_000_000_000;

  const lockedAmount = ONE_GWEI;
  const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

  type DeployArgs = Parameters<typeof PoolFactory.deploy>;
  const args: DeployArgs = [padLock.getAddress()];

  const pool: Pool = (await PoolFactory.connect(deployer).deploy(...args)) as Pool;
  await pool.waitForDeployment();

  return { pool, padLock, poolManager, token };
}

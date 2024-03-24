import { PoolManager } from './../../../types/contracts/pools/PoolManager';
import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";



import { PadLock__factory, PoolManager, PoolManager__factory } from "../../../types";
import type { PadLock } from "../../../types/contracts/lock/PadLock";
import type { Pool } from "../../../types/contracts/pools/Pool";
import type { Pool__factory } from "../../../types/factories/contracts/pools/Pool__factory";


export async function poolFixture(): Promise<{
  pool: Pool;
  padLock: PadLock;
  poolManager: PoolManager;
  unlockTime: number;
  lockedAmount: number;
}> {

    // MockERC20Contract = await MockERC20Factory.deploy();
    // await MockERC20Contract.deployed();
    // changeCurrency(MockERC20Contract.address);
    // const PoolFactory = await ethers.getContractFactory(
    //   "contracts/pools/Pool.sol:Pool"
    // );
    // Pool = await PoolFactory.deploy(Lock.address);
    // await Pool.deployed();
    // const PoolManagerFactory = await ethers.getContractFactory(
    //   "contracts/pools/PoolManager.sol:PoolManager"
    // );
    // PoolManager = await PoolManagerFactory.deploy(signerAddress, Pool.address);
    // await PoolManager.deployed();
    // await MockERC20Contract.connect(deployers).approve(
    //   PoolManager.address,
    //   tokenAmount
    // );

  const signers = await ethers.getSigners();
  const deployer: SignerWithAddress = signers[0];

  const PoolFactory: Pool__factory = (await ethers.getContractFactory("Pool")) as Pool__factory;
  const PoolManagerFactory: PoolManager__factory = (await ethers.getContractFactory("PoolManager")) as PoolManager__factory;
  const PadLockFactory: PadLock__factory = (await ethers.getContractFactory(
    "PadLock"
  )) as PadLock__factory;


  const padLock: PadLock = (await PadLockFactory.connect(deployer).deploy()) as PadLock;
  await padLock.waitForDeployment();

  const poolManager: PoolManager = (await PoolManagerFactory.connect(deployer).deploy(deployer.address,padLock.getAddress())) as PoolManager;
  await poolManager.waitForDeployment();


  const ONE_YEAR_IN_SECS = time.duration.years(1);
  const ONE_GWEI = 1_000_000_000;

  const lockedAmount = ONE_GWEI;
  const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

  type DeployArgs = Parameters<typeof PoolFactory.deploy>;
  const args: DeployArgs = [padLock.getAddress()];

  const pool: Pool = (await PoolFactory.connect(deployer).deploy(...args)) as Pool;
  await pool.waitForDeployment();

  return { pool, padLock, poolManager,unlockTime, lockedAmount };
}

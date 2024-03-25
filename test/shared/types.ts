import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";



import { MockERC20, PadLock } from "../../types";
import type { Pool } from "../../types/contracts/pools/Pool";
import { PoolManager } from "./../../types/contracts/pools/PoolManager";

type Fixture<T> = () => Promise<T>;

declare module "mocha" {
  export interface Context {
    contracts: Contracts;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
  }
}

export interface Contracts {
  pool: Pool;
  padLock: PadLock;
  poolManager: PoolManager;
  mockERC20: MockERC20;
}

export interface Signers {
  deployer: SignerWithAddress;
  accounts: SignerWithAddress[];
}
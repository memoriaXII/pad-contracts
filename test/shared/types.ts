import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";



import type { Pool } from "../../types/contracts/pools/Pool";

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
}

export interface Signers {
  deployer: SignerWithAddress;
  accounts: SignerWithAddress[];
}
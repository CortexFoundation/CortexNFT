import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import dotenv from 'dotenv';

dotenv.config();

const config: HardhatUserConfig = {
  networks:{
    hardhat: {
      blockGasLimit: 30000000000,
      allowUnlimitedContractSize:true,
    },
    rinkeby:{
      url: "https://eth-rinkeby.alchemyapi.io/v2/" + process.env.ALCHEMY_KEY,
      // @ts-ignore
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  contractSizer: {
    strict: true,
  }
};

export default config;

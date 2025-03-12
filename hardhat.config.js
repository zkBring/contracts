require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require('dotenv').config();

const { PRIVATE_KEY, BASE_RPC_URL } = process.env;

module.exports = {
  solidity: "0.8.10",
  networks: {
    base: {
      url: BASE_RPC_URL,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
};

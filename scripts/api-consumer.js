// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { utils } = require("ethers");
require("dotenv").config();

const { ALPHA_VANTAGE_API_KEY } = process.env;

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // Deploy the contract on the blockchain
  const contractFactory = await hre.ethers.getContractFactory("StockAPIConsumer");
  // TODO: Update both values.
  const oracleAddress = "0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8";
  const jobId = "d5270d1c311941d0b08bead21fea7747";
  const contract = await contractFactory.deploy(ethers.constants.AddressZero, oracleAddress, ethers.utils.hexlify(ethers.utils.toUtf8Bytes(jobId)), ALPHA_VANTAGE_API_KEY);
  await contract.deployed();
  console.log("StockAPIConsumer contract deployed to:", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
require('dotenv').config('..');

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // Check if we're deploying in CI or not.
  const deployingInCI = process.env.CI === "true";

  // Deploy the contract on the blockchain.
  if (!deployingInCI) {
    console.log("Deploying contract...");
  }
  const contractFactory = await hre.ethers.getContractFactory("Fund");
  const contract = await contractFactory.deploy();
  await contract.deployed();
  if (deployingInCI) {
    console.log(`${contract.address}`);
  } else {
    console.log("Fund contract deployed to:", contract.address);

    // Verify the contract on snowtrace.
    console.log(`Verify with: $ npx hardhat verify ${contract.address} --network ${hre.network.name}`);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// Deploy and verify the CollateralFundV1 contract on the specified network.
// It also handles localhost deployments.
const hre = require("hardhat");
require("dotenv").config();

const { collateralFundConfig } = require("../helper.config");

async function main() {
  // Common parameters.
  const hubAddress = collateralFundConfig.common.hubAddress;

  // Network-specific parameters.
  let usdcTokenAddress;
  if (hre.network.config.chainId == 31337) {
		// The contract is deployed on localhost so we deploy the mock contracts.

		// Deploy the MockUsdcToken contract.
		const usdcTokenContractFactory = await hre.ethers.getContractFactory("USDCToken");
		usdcTokenContract = await usdcTokenContractFactory.deploy(100000);
		await usdcTokenContract.deployed();
		console.log("MockUsdcToken contract deployed to:", usdcTokenContract.address);
		usdcTokenAddress = usdcTokenContract.address;
	} else {
		// Retrieve network-specific parameters.
		const chainId = hre.network.config.chainId;
		usdcTokenAddress = collateralFundConfig.network[chainId].usdcTokenAddress;
	}

  // Deploy the contract.
	const collateralFundFactory = await hre.ethers.getContractFactory("CollateralFundV1");
	const collateralFundContract = await collateralFundFactory.deploy(usdcTokenAddress, hubAddress);
	await collateralFundContract.deployed();
	console.log("CollateralFundV1 contract deployed to:", collateralFundContract.address);

	// Verify the contract.
	console.log(`Verify with: $ npx hardhat verify ${collateralFundContract.address} ${usdcTokenAddress} ${hubAddress} --contract contracts/CollateralFundV1.sol:CollateralFundV1 --network ${hre.network.name}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

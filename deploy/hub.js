// Deploy and verify the SimpleHubV1 contract on the specified network.
// It also handles localhost deployments.
const hre = require("hardhat");
require("dotenv").config();

async function main() {
	// Deploy the contract.
	const hubFactory = await hre.ethers.getContractFactory("SimpleHubV1");
	const hubContract = await hubFactory.deploy();
	await hubContract.deployed();
	console.log("SimpleHubV1 contract deployed to:", hubContract.address);

	// Verify the contract.
	console.log(`Verify with: $ npx hardhat verify ${hubContract.address} --contract contracts/SimpleHubV1.sol:SimpleHubV1 --network ${hre.network.name}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});

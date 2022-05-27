// Deploy and verify the PriceTrackerV1 contract on the specified network.
// It also handles localhost deployments.
const hre = require("hardhat");
require("dotenv").config();

const { priceTrackerConfig } = require("../helper.config");

async function main() {
	// Common parameters.
	const apiKey = priceTrackerConfig.common.apiKey;
	const updateInterval = priceTrackerConfig.common.updateInterval;

	// Network-specific parameters.
	let linkTokenAddress, aggregatorAddress, oracleAddress, jobId;
	if (hre.network.config.chainId == 31337) {
		// The contract is deployed on localhost so we deploy the mock contracts.

		// 1. Deploy the MockLinkToken contract.
		const linkTokenContractFactory = await hre.ethers.getContractFactory("LinkToken");
		const linkTokenContract = await linkTokenContractFactory.deploy();
		await linkTokenContract.deployed();
		console.log("MockLinkToken contract deployed to:", linkTokenContract.address);
		linkTokenAddress = linkTokenContract.address;

		// 2. Deploy the MockV3Aggregator contract.
		const aggregatorContractFactory = await hre.ethers.getContractFactory("MockV3Aggregator");
		const aggregatorContract = await aggregatorContractFactory.deploy(2, 10);
		await aggregatorContract.deployed();
		console.log("MockV3Aggregator contract deployed to:", aggregatorContract.address);
		aggregatorAddress = aggregatorContract.address;

		// 3. Deploy the MockOracle contract.
		const oracleContractFactory = await hre.ethers.getContractFactory("MockOracle");
		const oracleContract = await oracleContractFactory.deploy(linkTokenContract.address);
		await oracleContract.deployed();
		console.log("MockOracle contract deployed to:", oracleContract.address);
		oracleAddress = oracleContract.address;

		// Set a random bytes32 job ID.
		jobId = hre.ethers.utils.randomBytes(32);
	} else {
		// Retrieve network-specific parameters.
		const chainId = hre.network.config.chainId;
		linkTokenAddress = priceTrackerConfig.network[chainId].linkTokenAddress;
		aggregatorAddress = priceTrackerConfig.network[chainId].aggregatorAddress;
		oracleAddress = priceTrackerConfig.network[chainId].oracleAddress;
		jobId = priceTrackerConfig.network[chainId].jobId;
	}

	// Deploy the contract.
	const priceTrackerFactory = await hre.ethers.getContractFactory("PriceTrackerV1");
	const priceTrackerContract = await priceTrackerFactory.deploy(
		linkTokenAddress,
		aggregatorAddress,
		oracleAddress,
		jobId,
		apiKey,
		updateInterval
	);
	await priceTrackerContract.deployed();
	console.log("PriceTrackerV1 contract deployed to:", priceTrackerContract.address);

	// Verify the contract.
	console.log(`Verify with: $ npx hardhat verify ${priceTrackerContract.address} ${linkTokenAddress} ${aggregatorAddress} ${oracleAddress} ${jobId} ${apiKey} ${updateInterval} --contract contracts/PriceTrackerV1.sol:PriceTrackerV1 --network ${hre.network.name}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});

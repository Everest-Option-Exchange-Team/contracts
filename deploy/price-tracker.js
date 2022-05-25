// Deploy and verify the PriceTrackerV1 on the specified network.
// It also handles localhost deployments.
const hre = require("hardhat");
require("dotenv").config();

async function main() {
	let linkTokenAddress, aggregatorAddress, oracleAddress, jobId;

	// Parameters common to all networks. 
	const apiKey = process.env.ALPHA_VANTAGE_API_KEY;
	const updateInterval = 60; // in seconds.

	// Network-specific parameters.
	if (hre.network.config.chainId == 31337) {
		// The contract is deployed on the localhost network.

		// Deploy the mock contracts.
		const linkTokenContractFactory = await hre.ethers.getContractFactory("LinkToken");
		const linkTokenContract = await linkTokenContractFactory.deploy();
		await linkTokenContract.deployed();
		console.log("LINK token contract deployed to:", linkTokenContract.address);
		linkTokenAddress = linkTokenContract.address;
	} else if (hre.network.config.chainId == 42) {
		// The contract is deployed on the Kovan testnet.

		// No need to specify the link token address on Kovan as the address is registered automatically.
		linkTokenAddress = ethers.constants.AddressZero;
		aggregatorAddress = "0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60";
		oracleAddress = "0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8";
		// The initial jobId was: d5270d1c311941d0b08bead21fea7747.
		// Converted to bytes32/hex using https://web3-type-converter.onbrn.com/.
		jobId = "0x6435323730643163333131393431643062303862656164323166656137373437";
	} else if (hre.network.config.chainId == 43113) {
		// The contract is deployed on the Fuji testnet (it might not work at the moment).

		linkTokenAddress = "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846";
		// There are no data feeds available for the USDC/USD pair on the Fuji testnet yet.
		// TODO: Find a way to get the USDC/USD price, maybe use the Aplha Vantage API?
		aggregatorAddress = ethers.constants.AddressZero;
		// Since Chainlink does not provide a node to make GET requests on any API on the Fuji testnet,
		// we had to use our custom node. That's why we started working with https://linkwellnodes.io/
		// node operator (custom oracle address and job ID).
		oracleAddress = "0xAc6Fbccc8cFbE2e05C23DFB638f37C838c47760C";
		// The initial jobId was: 70f4f19746e94277a32ddfa0358b8901.
		// Converted to bytes32/hex using https://web3-type-converter.onbrn.com/.
		jobId = "0x3730663466313937343665393432373761333264646661303335386238393031";
	}

	// Deploy the PriceTrackerV1 contract.
	const contractFactory = await hre.ethers.getContractFactory("PriceTrackerV1");
	const contract = await contractFactory.deploy(
		linkTokenAddress,
		aggregatorAddress,
		oracleAddress,
		jobId,
		apiKey,
		updateInterval
	);
	await contract.deployed();
	console.log("PriceTrackerV1 contract deployed to:", contract.address);

	// Verify the PriceTrackerV1 contract.
	console.log(`Verify with: $ npx hardhat verify ${contract.address} ${linkTokenAddress} ${aggregatorAddress} ${oracleAddress} ${jobId} ${apiKey} ${updateInterval} --contract contracts/PriceTrackerV1.sol:PriceTrackerV1 --network ${hre.network.name}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});

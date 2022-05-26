const hre = require("hardhat");
const { utils } = require("ethers");
const { expect } = require("chai");

describe("PriceTrackerV1 smart contract tests", () => {
	let priceTrackerContract, oracleContract, owner, user, oracle, temp;

	beforeEach(async () => {
		[owner, user, oracle, temp] = await hre.ethers.getSigners();

		// Deploy the MockLinkToken contract.
		const linkTokenContractFactory = await hre.ethers.getContractFactory("LinkToken");
		const linkTokenContract = await linkTokenContractFactory.deploy();
		await linkTokenContract.deployed();

		// Deploy the MockV3Aggregator contract.
		const aggregatorContractFactory = await hre.ethers.getContractFactory("MockV3Aggregator");
		const aggregatorContract = await aggregatorContractFactory.deploy(2, 10);
		await aggregatorContract.deployed();

		// Deploy the MockOracle contract.
		const oracleContractFactory = await hre.ethers.getContractFactory("MockOracle");
		oracleContract = await oracleContractFactory.deploy(linkTokenContract.address);
		await oracleContract.deployed();

		// Deploy the PriceTrackerV1 contract.
		const priceTrackerFactory = await hre.ethers.getContractFactory("PriceTrackerV1");
		priceTrackerContract = await priceTrackerFactory.deploy(
			linkTokenContract.address,
			aggregatorContract.address,
			oracleContract.address,
			hre.ethers.utils.randomBytes(32),
			"my-api-key",
			60
		);
		await priceTrackerContract.deployed();

		// Fund the PriceTrackerV1 contract with some LINK tokens.
		await linkTokenContract.transfer(priceTrackerContract.address, utils.parseEther("1"));
	});

	describe("AddAsset and GetAssetList", () => {
		it("Add a new asset to the supported list of assets", async () => {
			// Check that the supported asset list is empty.
			let assetList = await priceTrackerContract.getAssetList();
			expect(assetList).to.be.empty;

			// Add three new assets to the supported asset list.
			let txn = await priceTrackerContract.addAsset("asset1");
			await txn.wait();

			txn = await priceTrackerContract.addAsset("asset2");
			await txn.wait();

			txn = await priceTrackerContract.addAsset("asset3");
			await txn.wait();

			// Check that the supported asset list is correctly updated.
			assetList = await priceTrackerContract.getAssetList();
			expect(assetList).to.eql(["asset1", "asset2", "asset3"]);

			// It should fail when any user tries to add a new asset.
			await priceTrackerContract.connect(user).addAsset("asset4").reverted;
		});
	});

	describe("Withdraw", () => {
		it("Should withdraw money from the fund", async () => {
			// It should succeed when the owner tries to withdraw funds (LINK tokens).
			const txn = await priceTrackerContract.withdraw();
			await txn.wait();

			// It should fail when any other user tries to withdraw funds.
			await priceTrackerContract.connect(user).withdraw().reverted;
		});
	});

	// TODO: Test updateUSDCPrice() (chainlink data feeds).

	// TODO: Test updateAssetPrice() (chainlink external adapters).
	/*
	describe("UpdateAssetPrice", () => {
		it("Should ask for the TSLA stock price", async () => {
			// Check the TSLA price stored in the contract is null.
			const tslaPrice = await priceTrackerContract.assetToPrice("TSLA");
			expect(tslaPrice.toNumber()).to.equal(0);

			// Request the new TSLA stock price.
			const txn = await priceTrackerContract.updateAssetPrice("TSLA");
			const transactionReceipt = await txn.wait();
			const requestId = transactionReceipt.events[0].topics[1];
			expect(requestId).to.not.be.null

			// TODO: Check the result.
			await mockOracleContract.fulfillOracleRequest(requestId, utils.formatBytes32String("TSLA"));
		});
	});
	*/

	// TODO: Test checkUpkeep() and performUpkeep() (chainlink keepers).

	// TODO: Test pause() and unpause().

	// TODO: Test getUSDCPrice().

	describe("GetAssetPrice", () => {
		it("Should get the price of an asset", async () => {
			// Add a new asset.
			const txn = await priceTrackerContract.addAsset("asset1");
			await txn.wait();

			// Get the asset price (it should be 0).
			const assetPrice = await priceTrackerContract.getAssetPrice("asset1");
			expect(assetPrice).to.equal(0);

			// It should fail when getting the price of an unsupported asset.
			await priceTrackerContract.getAssetPrice("asset2").reverted;
		});
	});

	// TODO: Test setHubAddress(), setAggregatorAddress() and setKeepersRegistryAddress().

	describe("SetOracleAddress", () => {
		it("Should update the oracle address", async () => {
			const txn = await priceTrackerContract.setOracleAddress(temp.address);
			await txn.wait();
		});
	});

	describe("SetJobID", () => {
		it("Should update the job ID", async () => {
			const txn = await priceTrackerContract.setJobId(ethers.constants.HashZero);
			await txn.wait();
		});
	});

	describe("SetAPIKey", () => {
		it("Should update the api key", async () => {
			const txn = await priceTrackerContract.setApiKey("test");
			await txn.wait();
		});
	});
});

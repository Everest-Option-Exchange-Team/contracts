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

			// It should fail when adding an empty asset.
			await expect(priceTrackerContract.addAsset(""))
				.to.be.revertedWith("The string parameter cannot be empty");

			// It should fail when adding an already supported asset.
			await expect(priceTrackerContract.addAsset("asset1"))
				.to.be.revertedWith("The asset must not already be registered in the contract");

			// Check that the supported asset list is correctly updated.
			assetList = await priceTrackerContract.getAssetList();
			expect(assetList).to.eql(["asset1", "asset2", "asset3"]);

			// It should fail when any user tries to add a new asset.
			await expect(priceTrackerContract.connect(user).addAsset("asset4"))
				.to.be.revertedWith("Only the hub and the owner can call this method");
		});
	});

	describe("Withdraw", () => {
		it("Should withdraw money from the fund", async () => {
			// It should succeed when the owner tries to withdraw funds (LINK tokens).
			const txn = await priceTrackerContract.withdraw();
			await txn.wait();

			// It should fail when any other user tries to withdraw funds.
			await expect(priceTrackerContract.connect(user).withdraw())
				.to.be.revertedWith("Only the owner can call this method");
		});
	});

	/**************************************** ChainLink Data Feeds ****************************************/

	describe("UpdateUSDCPrice", () => {
		it("Should update the USDC price", async () => {
			// TODO: Test that the MockV3Aggregator sends a response.

			// It should fail when any other user than the keepers registry
			// or the owner tries to update the price.
			await expect(priceTrackerContract.connect(user).updateUSDCPrice())
				.to.be.revertedWith("Only the keepers registry and the owner can call this method");
		});
	});

	/**************************************** ChainLink External Adapters ****************************************/

	describe("UpdateAssetPrice", () => {
		it("Should update the TSLA stock price", async () => {
			// Add the TSLA stock in the supported asset list.
			let txn = await priceTrackerContract.addAsset("TSLA");
			await txn.wait();

			// Check the TSLA price stored in the contract is null.
			const tslaPrice = await priceTrackerContract.getAssetPrice("TSLA");
			expect(tslaPrice.toNumber()).to.equal(0);

			// Request the new TSLA stock price.
			txn = await priceTrackerContract.updateAssetPrice("TSLA");
			const transactionReceipt = await txn.wait();
			const requestId = transactionReceipt.events[0].topics[1];
			expect(requestId).to.not.be.null

			// TODO: Check the oracle's response.
			await oracleContract.fulfillOracleRequest(requestId, utils.formatBytes32String("TSLA"));

			// It should fail when updating an empty asset.
			await expect(priceTrackerContract.updateAssetPrice(""))
				.to.be.revertedWith("The string parameter cannot be empty");

			// It should fail when updating an unsupported asset.
			await expect(priceTrackerContract.updateAssetPrice("my-asset"))
				.to.be.revertedWith("The asset must already be registered in the contract");

			// It should fail when any other user than the keepers registry
			// or the owner tries to update the price.
			await expect(priceTrackerContract.connect(user).updateAssetPrice("TSLA"))
				.to.be.revertedWith("Only the keepers registry and the owner can call this method");
		});
	});

	/**************************************** ChainLink Keepers ****************************************/

	describe("PerformUpkeep", async () => {
		it("Should update the price of all the supported assets", async () => {
			// TODO: Test the registry behaviour with mocks.

			// It should fail when any other user than the keepers registry
			// or the owner tries to update the price.
			await expect(priceTrackerContract.connect(user).performUpkeep(ethers.constants.HashZero))
				.to.be.revertedWith("Only the keepers registry and the owner can call this method");
		});
	});

	/**************************************** Pause / Unpause ****************************************/

	describe("Pause", () => {
		it("Should pause the contract", async () => {
			// Check that the contract is not paused.
			let isPaused = await priceTrackerContract.paused();
			expect(isPaused).to.be.false;

			// It should fail when a user tries to pause the contract.
			await expect(priceTrackerContract.connect(user).pause())
				.to.be.revertedWith("Only the owner can call this method");

			// Pause the contract.
			let txn = await priceTrackerContract.pause();
			await txn.wait();

			// Check that the contract is paused.
			isPaused = await priceTrackerContract.paused();
			expect(isPaused).to.be.true;

			// It should fail when the keepers registry tries to update the prices.
			await expect(priceTrackerContract.checkUpkeep(ethers.constants.HashZero))
				.to.be.revertedWith("The contract is paused and the automatic update of prices is stopped");

			// It should fail when the owner tries to pause the contract again.
			await expect(priceTrackerContract.pause())
				.to.be.revertedWith("The contract is already paused");
		});
	});

	describe("Unpause", () => {
		it("Should unpause the contract", async () => {
			// Pause the contract
			txn = await priceTrackerContract.pause();
			await txn.wait();

			// It should fail when a user tries to unpause the contract.
			await expect(priceTrackerContract.connect(user).unpause())
				.to.be.revertedWith("Only the owner can call this method");

			// Unpause the contract.
			txn = await priceTrackerContract.unpause();
			await txn.wait();

			// Check that the contract is unpaused.
			isPaused = await priceTrackerContract.paused();
			expect(isPaused).to.be.false;

			// It should not fail when the keepers registry tries to update the prices.
			const result = await priceTrackerContract.checkUpkeep(hre.ethers.constants.HashZero);
			expect(result[0]).to.be.oneOf([true, false]);

			// It should fail when the owner tries to unpause the contract again.
			await expect(priceTrackerContract.unpause())
				.to.be.revertedWith("The contract is not paused");
		});
	});

	/**************************************** Getters ****************************************/

	describe("GetUSDCprice", () => {
		it("Should get the USDC price", async () => {
			const price = await priceTrackerContract.getUSDCPrice();
			expect(price).to.equal(0);
		});
	});

	describe("GetAssetPrice", () => {
		it("Should get the price of an asset", async () => {
			// Add a new asset.
			const txn = await priceTrackerContract.addAsset("asset1");
			await txn.wait();

			// Get the asset price (it should be 0).
			const assetPrice = await priceTrackerContract.getAssetPrice("asset1");
			expect(assetPrice).to.equal(0);

			// It should fail when getting the price of an empty asset.
			await expect(priceTrackerContract.getAssetPrice(""))
				.to.be.revertedWith("The string parameter cannot be empty");

			// It should fail when getting the price of an unsupported asset.
			await expect(priceTrackerContract.getAssetPrice("my-asset"))
				.to.be.revertedWith("The asset must already be registered in the contract");
		});
	});

	/**************************************** Setters ****************************************/

	describe("SetHubAddress", () => {
		it("Should update the hub address", async () => {
			// Update the address.
			const txn = await priceTrackerContract.setHubAddress(temp.address);
			await txn.wait();

			// It should fail when updating with a null address.
			await expect(priceTrackerContract.setHubAddress(ethers.constants.AddressZero))
				.to.be.revertedWith("The address parameter cannot be null");

			// It should fail when updating the address as any user.
			await expect(priceTrackerContract
				.connect(user)
				.setHubAddress(temp.address)
			).to.be.revertedWith("Only the owner can call this method");
		});
	});

	describe("SetAggregatorAddress", () => {
		it("Should update the aggregator address", async () => {
			// Update the address.
			const txn = await priceTrackerContract.setAggregatorAddress(temp.address);
			await txn.wait();

			// It should fail when updating with a null address.
			await expect(priceTrackerContract.setAggregatorAddress(ethers.constants.AddressZero))
				.to.be.revertedWith("The address parameter cannot be null");

			// It should fail when updating the address as any user.
			await expect(priceTrackerContract
				.connect(user)
				.setAggregatorAddress(temp.address)
			).to.be.revertedWith("Only the owner can call this method");
		});
	});

	describe("SetKeepersRegistryAddress", () => {
		it("Should update the keepers registry address", async () => {
			// Update the address.
			const txn = await priceTrackerContract.setKeepersRegistryAddress(temp.address);
			await txn.wait();

			// It should fail when updating with a null address.
			await expect(priceTrackerContract.setKeepersRegistryAddress(ethers.constants.AddressZero))
				.to.be.revertedWith("The address parameter cannot be null");

			// It should fail when updating the address as any user.
			await expect(priceTrackerContract
				.connect(user)
				.setKeepersRegistryAddress(temp.address)
			).to.be.revertedWith("Only the owner can call this method");
		});
	});

	describe("SetOracleAddress", () => {
		it("Should update the oracle address", async () => {
			// Update the address.
			const txn = await priceTrackerContract.setOracleAddress(temp.address);
			await txn.wait();

			// It should fail when updating with a null address.
			await expect(priceTrackerContract.setOracleAddress(ethers.constants.AddressZero))
				.to.be.revertedWith("The address parameter cannot be null");

			// It should fail when updating the address as any user.
			await expect(priceTrackerContract
				.connect(user)
				.setOracleAddress(temp.address)
			).to.be.revertedWith("Only the owner can call this method");
		});
	});

	describe("SetJobId", () => {
		it("Should update the job id", async () => {
			// Update the job id.
			const txn = await priceTrackerContract.setJobId(hre.ethers.utils.randomBytes(32));
			await txn.wait();

			// It should fail when updating with an empty bytes32.
			// However, it's not possible test.

			// It should fail when updating the job id as any user.
			await expect(priceTrackerContract
				.connect(user)
				.setJobId(hre.ethers.utils.randomBytes(32))
			).to.be.revertedWith("Only the owner can call this method");
		});
	});

	describe("SetAPIKey", () => {
		it("Should update the API key", async () => {
			// Update the API key.
			const txn = await priceTrackerContract.setApiKey("my-api-key");
			await txn.wait();

			// It should fail when updating with an empty string.
			await expect(priceTrackerContract.setApiKey(""))
				.to.be.revertedWith("The string parameter cannot be empty");

			// It should fail when updating the api key as any user.
			await expect(priceTrackerContract
				.connect(user)
				.setApiKey("my-api-key")
			).to.be.revertedWith("Only the owner can call this method");
		});
	});

	/**************************************** For test purposes ****************************************/

	describe("SetAssetPrice", () => {
		it("Should update the price of the TSLA asset", async () => {
			// Add the TSLA stock in the supported asset list.
			let txn = await priceTrackerContract.addAsset("TSLA");
			await txn.wait();

			// Check the TSLA price stored in the contract is null.
			let tslaPrice = await priceTrackerContract.getAssetPrice("TSLA");
			expect(tslaPrice.toNumber()).to.equal(0);

			// Update the TSLA stock price to $123,45.
			txn = await priceTrackerContract.setAssetPrice("TSLA", 12345);
			await txn.wait();

			// Check that the TSLA price has been updated.
			tslaPrice = await priceTrackerContract.getAssetPrice("TSLA");
			expect(tslaPrice.toNumber()).to.equal(12345);

			// It should fail when updating the price of an empty asset.
			await expect(priceTrackerContract.setAssetPrice("", 12345))
				.to.be.revertedWith("The string parameter cannot be empty");

			// It should fail when updating the price of an unsupported asset.
			await expect(priceTrackerContract.setAssetPrice("my-asset", 12345))
				.to.be.revertedWith("The asset must already be registered in the contract");

			// It should fail when any other user than the keepers registry
			// or the owner tries to update the price.
			await expect(priceTrackerContract.connect(user).setAssetPrice("TSLA", 12345))
				.to.be.revertedWith("Only the owner can call this method");
		});
	});
});

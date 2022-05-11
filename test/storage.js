const hre = require("hardhat");
const { utils } = require("ethers");
const { network } = require("hardhat");
const { expect } = require("chai");

// Check if we're deploying to a local blockchain.
// If yes, run the tests.
const LOCAL_CHAIN_ID = 31337;
if (network.config.chainId === LOCAL_CHAIN_ID) {
	describe("Price Consumer smart contract tests", () => {
		let storageContract, mockOracleContract, owner, user, oracle, temp;

		beforeEach(async () => {
			// Define an owner and a user.
			const accounts = await hre.ethers.getSigners();
			owner = accounts[0];
			user = accounts[1];
			oracle = accounts[2];
			temp = accounts[3];

			// Deploy all the mock contracts.
			// 1. Deploy a mock link token contract.
			const linkTokenContractFactory = await hre.ethers.getContractFactory("LinkToken");
			const linkTokenContract = await linkTokenContractFactory.deploy();
			await linkTokenContract.deployed();
			console.log("LINK token contract deployed to:", linkTokenContract.address);

			// 2. Deploy a mock oracle contract.
			const mockOracleContractFactory = await hre.ethers.getContractFactory("MockOracle");
			mockOracleContract = await mockOracleContractFactory.deploy(linkTokenContract.address);
			await mockOracleContract.deployed();
			console.log("Mock oracle contract deployed to:", mockOracleContract.address);

			// Deploy the stock api consumer contract.
			const storageContractFactory = await hre.ethers.getContractFactory("Storage");
			storageContract = await storageContractFactory.deploy(linkTokenContract.address, oracle.address, ethers.constants.HashZero, "apikey");
			await storageContract.deployed();
			console.log("Storage contract deployed to:", storageContract.address);

			// Fund the stock api consumer contract with some LINK tokens.
			await linkTokenContract.transfer(storageContract.address, utils.parseEther("1"));
			console.log("Storage contract funded with 1 LINK token");
		});

		/*
		// TODO: Write the request price test function.
		describe("UpdateAssetPrice", () => {
			it("Should ask for the TSLA stock price", async () => {
				// Check the TSLA price stored in the contract is null.
				const tslaPrice = await storageContract.assetToPrice("TSLA");
				expect(tslaPrice.toNumber()).to.equal(0);

				// Request the new TSLA stock price.
				const txn = await storageContract.updateAssetPrice("TSLA");
				const transactionReceipt = await txn.wait();
				const requestId = transactionReceipt.events[0].topics[1];
				console.log("ID of the TSLA stock price request:", requestId);
				expect(requestId).to.not.be.null

				// TODO: Check the result.
				await mockOracleContract.fulfillOracleRequest(requestId, utils.formatBytes32String("TSLA"));
			});
		});
		*/

		describe("AddAsset and GetAssetList", () => {
			it("Add a new asset to the supported list of assets", async () => {
				// Check that the supported asset list is empty.
				let assetList = await storageContract.getAssetList();
            	expect(assetList).to.be.empty;

				// Add three new assets to the supported asset list.
				let txn = await storageContract.addAsset("asset1");
				await txn.wait();

				txn = await storageContract.addAsset("asset2");
				await txn.wait();

				txn = await storageContract.addAsset("asset3");
				await txn.wait();

				// Check that the supported asset list is correctly updated.
				assetList = await storageContract.getAssetList();
            	expect(assetList).to.eql(["asset1", "asset2", "asset3"]);

				// It should fail when any user tries to add a new asset.
				await storageContract.connect(user).addAsset("asset4").reverted;
			});
		});

		describe("GetAssetPrice", () => {
			it("Should get the price of an asset", async () => {
				// Add a new asset.
				const txn = await storageContract.addAsset("asset1");
				await txn.wait();

				// Get the asset price (it should be 0).
				const assetPrice = await storageContract.getAssetPrice("asset1");
				expect(assetPrice).to.equal(0);

				// It should fail when getting the price of an unsupported asset.
				await storageContract.getAssetPrice("asset2").reverted;
			});
		});

		describe("UpdateOracleAddress", () => {
			it("Should update the oracle address", async () => {
				const txn = await storageContract.updateOracleAddress(temp.address);
				await txn.wait();
			});
		});

		describe("UpdateJobID", () => {
			it("Should update the job ID", async () => {
				const txn = await storageContract.updateJobId(ethers.constants.HashZero);
				await txn.wait();
			});
		});

		describe("UpdateApiKey", () => {
			it("Should update the api key", async () => {
				const txn = await storageContract.updateApiKey("test");
				await txn.wait();
			});
		});

		describe("Withdraw", () => {
			it("Should withdraw money from the fund", async () => {
				// It should succeed when the owner tries to withdraw funds (LINK tokens).
				const txn = await storageContract.connect(owner).withdraw();
				await txn.wait();

				// It should fail when any other user tries to withdraw funds.
				await storageContract.connect(user).withdraw().reverted;
			});
		});
	});
}

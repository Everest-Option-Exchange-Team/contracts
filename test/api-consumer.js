const hre = require("hardhat");
const { utils } = require("ethers");
const { network } = require("hardhat");
const { expect } = require("chai");

// Check if we're deploying to a local blockchain.
// If yes, run the tests.
const LOCAL_CHAIN_ID = 31337;
if (network.config.chainId === LOCAL_CHAIN_ID) {
	describe("Price Consumer smart contract tests", () => {
		let stockAPIConsumerContract, mockOracleContract, owner, user, oracle, temp;

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
			const stockAPIConsumerContractFactory = await hre.ethers.getContractFactory("StockAPIConsumer");
			stockAPIConsumerContract = await stockAPIConsumerContractFactory.deploy(linkTokenContract.address, oracle.address, ethers.constants.HashZero, "apikey");
			await stockAPIConsumerContract.deployed();
			console.log("StockAPIConsumer contract deployed to:", stockAPIConsumerContract.address);

			// Fund the stock api consumer contract with some LINK tokens.
			await linkTokenContract.transfer(stockAPIConsumerContract.address, utils.parseEther("1"));
			console.log("StockAPIConsumer contract funded with 1 LINK token");
		});

		/*
		// TODO: Write the request price test function.
		describe("RequestPrice", () => {
			it("Should ask for the TSLA stock price", async () => {
				// Check the TSLA price stored in the contract is null.
				const tslaPrice = await stockAPIConsumerContract.stockToPrices("TSLA");
				expect(tslaPrice.toNumber()).to.equal(0);

				// Request the new TSLA stock price.
				const txn = await stockAPIConsumerContract.requestPrice("TSLA");
				const transactionReceipt = await txn.wait();
				const requestId = transactionReceipt.events[0].topics[1];
				console.log("ID of the TSLA stock price request:", requestId);
				expect(requestId).to.not.be.null

				// TODO: Check the result.
				await mockOracleContract.fulfillOracleRequest(requestId, utils.formatBytes32String('TSLA'));
			});
		});
		*/

		describe("UpdateOracleAddress", () => {
			it("Should update the oracle address", async () => {
				const txn = await stockAPIConsumerContract.updateOracleAddress(temp.address);
				await txn.wait();
			});
		});

		describe("UpdateJobID", () => {
			it("Should update the job ID", async () => {
				const txn = await stockAPIConsumerContract.updateJobId(ethers.constants.HashZero);
				await txn.wait();
			});
		});

		describe("UpdateApiKey", () => {
			it("Should update the api key", async () => {
				const txn = await stockAPIConsumerContract.updateApiKey("test");
				await txn.wait();
			});
		});

		describe("Withdraw", () => {
			it("Should withdraw money from the fund", async () => {
				// It should succeed when the owner tries to withdraw funds (LINK tokens).
				const txn = await stockAPIConsumerContract.connect(owner).withdraw();
				await txn.wait();

				// It should fail when any other user tries to withdraw funds.
				await stockAPIConsumerContract.connect(user).withdraw().reverted;
				await stockAPIConsumerContract.connect(oracle).withdraw().reverted;
				await stockAPIConsumerContract.connect(temp).withdraw().reverted;
			});
		});
	});
}

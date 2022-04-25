const hre = require("hardhat");
const { network } = require("hardhat");

// Check if we're deploying to a local blockchain.
// If yes, run the tests.
const LOCAL_CHAIN_ID = 31337;
if (network.config.chainId === LOCAL_CHAIN_ID) {
    describe("Price Consumer smart contract tests", () => {
        let stockAPIConsumerContract, owner, user, oracle, temp;

        beforeEach(async () => {
            // Define an owner and a user.
            const accounts = await hre.ethers.getSigners();
            owner = accounts[0];
            user = accounts[1];
            oracle = accounts[2];
            temp = accounts[3];

            // Deploy a mock link token contract.
            const linkTokenContractFactory = await hre.ethers.getContractFactory("LinkToken");
            const linkTokenContract = await linkTokenContractFactory.deploy();
            await linkTokenContract.deployed();
            console.log("LINK token contract deployed to:", linkTokenContract.address);

            // Deploy the stock api consumer contract.
            const stockAPIConsumerContractFactory = await hre.ethers.getContractFactory("StockAPIConsumer");
            stockAPIConsumerContract = await stockAPIConsumerContractFactory.deploy(linkTokenContract.address, oracle.address, ethers.constants.HashZero, "apikey");
            await stockAPIConsumerContract.deployed();
            console.log("StockAPIConsumer contract deployed to:", stockAPIConsumerContract.address);

            /*
            // URL: https://github.com/smartcontractkit/hardhat-starter-kit/blob/main/test/unit/APIConsumer_unit_test.js

            // Deploy the mock oracle contract.
            const mockOracleContractFactory = await hre.ethers.getContractFactory("MockOracle");
            const mockOracleContract = await mockOracleContractFactory.deploy();
            await mockOracleContract.deployed();
            console.log("Mock oracle contract deployed to:", mockOracleContract.address);

            // Deploy the link token contract.
            const linkTokenContractFactory = await hre.ethers.getContractFactory("LinkToken");
            const linkTokenContract = await linkTokenContractFactory.deploy();
            await linkTokenContract.deployed();
            console.log("LINK token contract deployed to:", linkTokenContract.address);

            // Fund the stock api consumer contract with some LINK tokens.
            await hre.run("fund-link", { contract: stockAPIConsumerContract.address, linkaddress: linkTokenContract.address })
            */
        });

        describe("RequestPrice", () => {
            console.log("TODO");
        });

        describe("Fulfill", () => {
            console.log("TODO");
        });


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

const hre = require("hardhat");
require("dotenv").config();
const { utils } = require("ethers");
const { expect } = require("chai");

const { ALPHA_VANTAGE_API_KEY } = process.env;

describe("Price Consumer smart contract tests", () => {
    let contract, owner, user;

    beforeEach(async () => {
        // Define an owner and a user.
        const accounts = await hre.ethers.getSigners();
        owner = accounts[0];
        user = accounts[1];

        // Deploy the contract on the blockchain
        const contractFactory = await hre.ethers.getContractFactory("APIConsumer");
        const contract = await contractFactory.deploy(ALPHA_VANTAGE_API_KEY);
        await contract.deployed();
        console.log("APIConsumer contract deployed to:", contract.address);
    });


    describe("RequestPrice", () => {
        it("Should request the TSLA stock price", async () => {
            console.log(contract);
            
            // Send the request.
            const txn = await contract.requestPrice("TSLA");
            await txn.wait();
        });
    });
});
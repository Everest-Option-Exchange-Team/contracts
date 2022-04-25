const hre = require("hardhat");
const { utils } = require("ethers");
const { expect } = require("chai");

describe("Fund smart contract tests", () => {
    let contract, owner, user;

    beforeEach(async () => {
        // Define an owner and a user.
        const accounts = await hre.ethers.getSigners();
        owner = accounts[0];
        user = accounts[1];

        // Deploy the contract.
        const contractFactory = await hre.ethers.getContractFactory("Fund");
        contract = await contractFactory.deploy();
        await contract.deployed();
    });

    describe("Fund", () => {
        it("Should send money to the fund", async () => {
            // Note: here the user is the owner of the contract but it could be any other user.
            const amountDeposited = utils.parseEther("1.5");

            // Check that the user is not a funder.
            let funders = await contract.getFunders();
            expect(funders.includes(owner.address)).to.be.false;

            // Check that the user did not deposit anything to the fund.
            let amountFundedByUser = await contract.getAddressToAmountFunded(owner.address);
            expect(amountFundedByUser).to.equal(0);

            // Send money to the fund.
            const txn = await contract.fund({ value: amountDeposited });
            await txn.wait();

            // Check that the fund received the money.
            const funds = await contract.getTotalFunds();
            expect(funds).to.equal(amountDeposited);

            // Check that the user is now a funder.
            funders = await contract.getFunders();
            expect(funders.includes(owner.address)).to.be.true;

            // Check that the amount funded by the user is equal to the amount deposited.
            amountFundedByUser = await contract.getAddressToAmountFunded(owner.address);
            expect(amountFundedByUser).to.equal(amountDeposited);
        });
    })

    describe("Withdraw", () => {
        it("Should withdraw money from the fund", async () => {
            // Note: here the user is the owner of the contract but it could be any other user.
            const amountDeposited = utils.parseEther("1.5");

            // Check that the fund is empty.
            let funds = await contract.getTotalFunds();
            expect(funds).to.equal(0);

            // Send money to the fund.
            const txn = await contract.fund({ value: amountDeposited });
            await txn.wait();

            // Check that the fund received the money.
            funds = await contract.getTotalFunds();
            expect(funds).to.equal(amountDeposited);

            // Withdraw only one ether from the fund.
            const txn2 = await contract.withdraw(utils.parseEther("1"));
            await txn2.wait();

            // Check that the fund is now empty.
            funds = await contract.getTotalFunds();
            expect(funds).to.equal(utils.parseEther(".5"));
        });
    })

    describe("GetFunders", () => {
        it("Should add the user to the funders list", async () => {
            // Check that the owner and the user are not funders.
            let funders = await contract.getFunders();
            expect(funders.includes(owner.address)).to.be.false;
            expect(funders.includes(user.address)).to.be.false;

            // The user sends money to the fund.
            const txn = await contract.connect(user).fund({ value: utils.parseEther("1.5") });
            await txn.wait();

            // Check that user is added to the funders list.
            // Also check that the owner is still not a funder.
            funders = await contract.getFunders();
            expect(funders.includes(owner.address)).to.be.false;
            expect(funders.includes(user.address)).to.be.true;
        });
    })

    describe("GetAddressToAmountFunded", () => {
        it("Should return the amount deposited by the user", async () => {
            // Check that the owner and the user have deposited nothing to the fund.
            let amountFundedByOwner = await contract.getAddressToAmountFunded(owner.address);
            expect(amountFundedByOwner).to.equal(0);

            let amountFundedByUser = await contract.getAddressToAmountFunded(user.address);
            expect(amountFundedByUser).to.equal(0);

            // The user sends money to the fund.
            const txn = await contract.connect(user).fund({ value: utils.parseEther("1.5") });
            await txn.wait();

            // Check that the user has deposited money to the fund.
            // Also check that the owner has still deposited nothing.
            amountFundedByOwner = await contract.getAddressToAmountFunded(owner.address);
            expect(amountFundedByOwner).to.equal(0);

            amountFundedByUser = await contract.getAddressToAmountFunded(user.address);
            expect(amountFundedByUser).to.equal(utils.parseEther("1.5"));
        });
    })

    describe("GetTotalFunds", () => {
        it("Should return the amount deposited to the fund", async () => {
            // Check that the fund amount is empty.
            let funds = await contract.getTotalFunds();
            expect(funds).to.equal(0);

            // The owner and user deposit money to the fund.
            const txn = await contract.fund({ value: utils.parseEther("1") });
            await txn.wait();

            const txn2 = await contract.connect(user).fund({ value: utils.parseEther("1.5") });
            await txn2.wait();

            // Check that the fund amount is equal to what's have been deposited.
            funds = await contract.getTotalFunds();
            expect(funds).to.equal(utils.parseEther("2.5"));
        });
    })
});
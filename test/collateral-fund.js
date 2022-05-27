const hre = require("hardhat");
const { utils } = require("ethers");
const { expect } = require("chai");

describe("CollateralFundV1 smart contract tests", () => {
    let usdcTokenContract, collateralFundContract, owner, user, hub, temp;

    beforeEach(async () => {
        [owner, user, hub, temp] = await hre.ethers.getSigners();

        // Deploy the MockUSDCToken contract.
        const usdcTokenContractFactory = await hre.ethers.getContractFactory("USDCToken");
        usdcTokenContract = await usdcTokenContractFactory.deploy(100000);
        await usdcTokenContract.deployed();

        // Deploy the CollateralFundV1 contract.
        const collateralFundContractFactory = await hre.ethers.getContractFactory("CollateralFundV1");
        collateralFundContract = await collateralFundContractFactory.deploy(usdcTokenContract.address, hub.address);
        await collateralFundContract.deployed();
    });

    /**************************************** Fund / Withdraw ****************************************/

    describe("Fund", () => {
        it("Should send USDC collateral to the fund", async () => {
            // Note: we user the owner account but we could also use any other user account.

            // Check that the user is not a funder.
            let funders = await collateralFundContract.getFunders();
            expect(funders.includes(owner.address)).to.be.false;

            // Check that the user has not deposited anything to the fund.
            let userCollateralAmount = await collateralFundContract.getUserCollateralAmount(owner.address);
            expect(userCollateralAmount).to.equal(0);

            // Approve the collateral fund to transfer 100 USDC from the user's wallet.
            let txn = await usdcTokenContract.approve(collateralFundContract.address, 100);
            await txn.wait();

            // Send 100 USDC collateral from the user's wallet to the fund.
            txn = await collateralFundContract.deposit(100);
            await txn.wait();

            // Check that the amount deposited by the user is equal to 100 USDC.
            userCollateralAmount = await collateralFundContract.getUserCollateralAmount(owner.address);
            expect(userCollateralAmount).to.equal(100);

            // Check that the fund received the money.
            const fundBalance = await usdcTokenContract.balanceOf(collateralFundContract.address);
            expect(fundBalance).to.equal(100);

            // Check that the user is now a funder.
            funders = await collateralFundContract.getFunders();
            expect(funders.includes(owner.address)).to.be.true;

            // It should fail when trying to deposit zero USDC to the fund.
            await expect(collateralFundContract.deposit(0))
                .to.be.revertedWith("Amount should be greator than zero");
        });
    })

    describe("Withdraw", () => {
        it("Should withdraw collateral from the fund", async () => {
            // Note: we user the owner account but we could also use any other user account.

            // Check that the fund is empty.
            let fundBalance = await usdcTokenContract.balanceOf(collateralFundContract.address);
            expect(fundBalance).to.equal(0);

            // Approve the collateral fund to transfer 100 USDC from the user's wallet.
            let txn = await usdcTokenContract.approve(collateralFundContract.address, 100);
            await txn.wait();

            // Send 100 USDC collateral from the user's wallet to the fund.
            txn = await collateralFundContract.deposit(100);
            await txn.wait();

            // Check that the amount deposited by the user is equal to 100 USDC.
            userCollateralAmount = await collateralFundContract.getUserCollateralAmount(owner.address);
            expect(userCollateralAmount).to.equal(100);

            // Check that the fund received the money.
            fundBalance = await usdcTokenContract.balanceOf(collateralFundContract.address);
            expect(fundBalance).to.equal(100);

            // Withdraw half of the deposited collateral.
            txn = await collateralFundContract.withdraw(10);
            await txn.wait();

            // Check that the amount deposited by the user is equal to 90 USDC.
            userCollateralAmount = await collateralFundContract.getUserCollateralAmount(owner.address);
            expect(userCollateralAmount).to.equal(90);

            // Check that the fund funds have been updated.
            fundBalance = await usdcTokenContract.balanceOf(collateralFundContract.address);
            expect(fundBalance).to.equal(90);

            // Check that the user is a funder.
            let funders = await collateralFundContract.getFunders();
            expect(funders.includes(owner.address)).to.be.true;

            // It should fail when a user tries to withdraw more USDC than what he deposited to the fund.
            await expect(collateralFundContract.withdraw(1000))
                .to.be.revertedWith("The user cannot withdraw more than what he deposited");

            // Withdraw all of the remaining deposited collateral.
            txn = await collateralFundContract.withdraw(90);
            await txn.wait();

            // Check that the user is no longer a funder.
            funders = await collateralFundContract.getFunders();
            expect(funders.includes(owner.address)).to.be.false;

            // It should fail when a user tries to withdraw USDC even though he haven't deposited anything to the fund.
            await expect(collateralFundContract.withdraw(1000))
                .to.be.revertedWith("The user has not deposited any collateral to the fund");

            // It should fail when trying to withdraw zero USDC to the fund.
            await expect(collateralFundContract.withdraw(0))
                .to.be.revertedWith("Amount should be greator than zero");

            // It should fail when a user that has not deposited tries to withdraw USDC from the fund.
            await expect(collateralFundContract.connect(user).withdraw(100))
                .to.be.revertedWith("The user has not deposited any collateral to the fund");
        });
    });

    /**************************************** Getters ****************************************/

    describe("GetUserCollateralAmount", () => {
        it("Should return the amount of collateral deposited by the user", async () => {
            // Check that the owner and the user have deposited nothing to the fund.
            let amountFundedByOwner = await collateralFundContract.getUserCollateralAmount(owner.address);
            expect(amountFundedByOwner).to.equal(0);

            let amountFundedByUser = await collateralFundContract.getUserCollateralAmount(user.address);
            expect(amountFundedByUser).to.equal(0);

            // Approve the collateral fund to transfer 100 USDC from the owner's wallet.
            let txn = await usdcTokenContract.approve(collateralFundContract.address, 100);
            await txn.wait();

            // Send 100 USDC collateral from the owner's wallet to the fund.
            txn = await collateralFundContract.deposit(100);
            await txn.wait();

            // Check that the owner has deposited money to the fund.
            // Also check that the user has still deposited nothing.
            amountFundedByOwner = await collateralFundContract.getUserCollateralAmount(owner.address);
            expect(amountFundedByOwner).to.equal(100);

            amountFundedByUser = await collateralFundContract.getUserCollateralAmount(user.address);
            expect(amountFundedByUser).to.equal(0);
        });
    });

    describe("GetFunders", () => {
        it("Should add the owner to the funders list", async () => {
            // Check that the owner and the user are not funders.
            let funders = await collateralFundContract.getFunders();
            expect(funders.includes(owner.address)).to.be.false;
            expect(funders.includes(user.address)).to.be.false;

            // Approve the collateral fund to transfer 100 USDC from the owner's wallet.
            let txn = await usdcTokenContract.approve(collateralFundContract.address, 100);
            await txn.wait();

            // Send 100 USDC collateral from the owner's wallet to the fund.
            txn = await collateralFundContract.deposit(100);
            await txn.wait();

            // Check that owner is added to the funders list.
            // Also check that the user is still not a funder.
            funders = await collateralFundContract.getFunders();
            expect(funders.includes(owner.address)).to.be.true;
            expect(funders.includes(user.address)).to.be.false;
        });
    })

    /**************************************** Setters ****************************************/

    describe("SetUserCollateralAmount", () => {
        it("Should update the user collateral amount", async () => {
            // Check that the user collateral amount is empty.
            let amountDeposited = await collateralFundContract.getUserCollateralAmount(user.address);
            expect(amountDeposited).to.equal(0);

            // Update the collateral amount.
            const txn = await collateralFundContract.connect(hub).setUserCollateralAmount(user.address, 100);
            await txn.wait();

            // Check that the user collateral amount has been updated.
            amountDeposited = await collateralFundContract.getUserCollateralAmount(user.address);
            expect(amountDeposited).to.equal(100);

            // It should fail when updating with a null address.
            await expect(collateralFundContract.connect(hub).setUserCollateralAmount(ethers.constants.AddressZero, 100))
                .to.be.revertedWith("The address parameter cannot be null");

            // It should fail when updating the collateral amount as any user.
            await expect(collateralFundContract.setUserCollateralAmount(user.address, 100))
                .to.be.revertedWith("Only the hub can call this method");
        });
    });

    describe("SetUsdcAddress", () => {
        it("Should update the usdc address", async () => {
            // Update the USDC address.
            const txn = await collateralFundContract.setUsdcAddress(temp.address);
            await txn.wait();

            // It should fail when updating with a null address.
            await expect(collateralFundContract.setUsdcAddress(ethers.constants.AddressZero))
                .to.be.revertedWith("The address parameter cannot be null");

            // It should fail when updating the address as any user.
            await expect(collateralFundContract.connect(user).setUsdcAddress(temp.address))
                .to.be.revertedWith("Only the owner can call this method");
        });
    });

    describe("SetHubAddress", () => {
        it("Should update the hub address", async () => {
            // Update the address.
            const txn = await collateralFundContract.setHubAddress(temp.address);
            await txn.wait();

            // It should fail when updating with a null address.
            await expect(collateralFundContract.setHubAddress(ethers.constants.AddressZero))
                .to.be.revertedWith("The address parameter cannot be null");

            // It should fail when updating the address as any user.
            await expect(collateralFundContract.connect(user).setHubAddress(temp.address))
                .to.be.revertedWith("Only the owner can call this method");
        });
    });
});
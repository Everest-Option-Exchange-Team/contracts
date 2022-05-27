const hre = require("hardhat");
const { utils } = require("ethers");
const { expect } = require("chai");

describe("SimpleHubV1 smart contract tests", () => {
    let usdcTokenContract, collateralFundContract, priceTrackerContract, syntheticTSLAContract, hubContract, owner, user, hub, temp;

    beforeEach(async () => {
        [owner, user, hub, temp] = await hre.ethers.getSigners();

        // 1. Deploy the CollateralFund contract
        // 1.1. Deploy the MockUSDCToken contract.
        const usdcTokenContractFactory = await hre.ethers.getContractFactory("USDCToken");
        usdcTokenContract = await usdcTokenContractFactory.deploy(100000);
        await usdcTokenContract.deployed();

        // 1.2. Deploy the CollateralFundV1 contract.
        const collateralFundContractFactory = await hre.ethers.getContractFactory("CollateralFundV1");
        collateralFundContract = await collateralFundContractFactory.deploy(usdcTokenContract.address, hub.address);
        await collateralFundContract.deployed();

        // 2. Deploy the PriceTracker contract
        // 2.1. Deploy the MockLinkToken contract.
		const linkTokenContractFactory = await hre.ethers.getContractFactory("LinkToken");
		const linkTokenContract = await linkTokenContractFactory.deploy();
		await linkTokenContract.deployed();

		// 2.2. Deploy the MockV3Aggregator contract.
		const aggregatorContractFactory = await hre.ethers.getContractFactory("MockV3Aggregator");
		const aggregatorContract = await aggregatorContractFactory.deploy(2, 10);
		await aggregatorContract.deployed();

		// 2.3. Deploy the MockOracle contract.
		const oracleContractFactory = await hre.ethers.getContractFactory("MockOracle");
		oracleContract = await oracleContractFactory.deploy(linkTokenContract.address);
		await oracleContract.deployed();

		// 2.4. Deploy the PriceTrackerV1 contract.
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

		// 2.5. Fund the PriceTrackerV1 contract with some LINK tokens.
		await linkTokenContract.transfer(priceTrackerContract.address, utils.parseEther("1"));

        // 3. Deploy a synthetic TSLA contract.
        const syntheticTSLAContractFactory = await hre.ethers.getContractFactory("SyntheticAssetV1");
        syntheticTSLAContract = await syntheticTSLAContractFactory.deploy("SyntheticTesla", "TSLA", hub.address);
        await syntheticTSLAContract.deployed();

        // 4. Deploy the SimpleHubV1 contract.
        const hubContractFactory = await hre.ethers.getContractFactory("SimpleHubV1");
        hubContract = await hubContractFactory.deploy();
        await hubContract.deployed();
    });

    /**************************************** Mint / Burn ****************************************/

    describe("MintSynthAsset", () => {
        it("Should mint TSLA synthetic assets", async () => {
            // Set the collateral fund address.
            let txn = await hubContract.setCollateralFundAddress(collateralFundContract.address);
            await txn.wait();

            // Set the price tracker address.
            txn = await hubContract.setPriceTrackerAddress(priceTrackerContract.address);
            await txn.wait();
            
            // Set the TLSA synth asset address.
            txn = await hubContract.setSynthAssetAddress("TSLA", syntheticTSLAContract.address);
            await txn.wait();

            // Update the hub address in the TSLa synth asset contract.
            txn = await syntheticTSLAContract.setHubAddress(hubContract.address);
            await txn.wait();

            // Add the TSLA synth asset to the price tracker supported list.
            txn = await priceTrackerContract.addAsset("TSLA");
			await txn.wait();

            // It should fail because the user has not provided any collateral.
            await expect(hubContract.mintSynthAsset("TSLA", 100, user.address))
                .to.be.revertedWith("The user has not enough collateral");

            // Provide collateral from the user wallet.
            // 1. Send 100 USDC from the owner wallet to the user wallet.
            txn = await usdcTokenContract.transfer(user.address, 100);
            await txn.wait();

            // 2. Approve the collateral fund to transfer 100 USDC from the user wallet.
            txn = await usdcTokenContract.connect(user).approve(collateralFundContract.address, 100);
            await txn.wait();

            // 3. Send 100 USDC collateral from the user wallet to the fund.
            txn = await collateralFundContract.connect(user).deposit(100);
            await txn.wait();

            // Manipulate the USDC price to set it to 1 USDC = 1 USD.
            txn = await priceTrackerContract.setUsdcPrice(1);
            await txn.wait();

            // Check that the user collateral value is equal to 100.
            userCollateralValue = await hubContract.getUserCollateralValue(user.address);
            expect(userCollateralValue).to.equal(100);

            // Manipulate the TSLA price to set it to 1 TSLA = 40 USD.
            txn = await priceTrackerContract.setAssetPrice("TSLA", 40);
            await txn.wait();

            // It should fail when trying to mint 10 synthetic TSLA (needs to 400*2 = 800 USD).
            await expect(hubContract.mintSynthAsset("TSLA", 10, user.address))
                .to.be.revertedWith("The user has not enough collateral");
            
            // Mint 1 synthetic TSLA to the user's wallet.
            // The user needs 40 * 2 = 80 USDC collateral to mint 1 synthetic TSLA.
            txn = await hubContract.mintSynthAsset("TSLA", 1, user.address);
            await txn.wait();

            // Check that the user position has been updated.
            let userTslaPosition = await hubContract.getUserPositionAmount("TSLA", user.address);
            expect(userTslaPosition).to.equal(1);

            // Check that the user total value minted has been updatd.
            let userTotalValueMinted = await hubContract.getUserTotalValueMinted(user.address);
            expect(userTotalValueMinted).to.equal(40);

            // It should fail when trying to mint synthetic assets with an empty symbol.
            await expect(hubContract.mintSynthAsset("", 100, owner.address))
                .to.be.revertedWith("The symbol parameter cannot be empty");

            // It should fail when trying to mint zero synthetic assets.
            await expect(hubContract.mintSynthAsset("TSLA", 0, owner.address))
                .to.be.revertedWith("The amount parameter has to be greater than zero");
        
            // It should fail when trying to mint synthetic assets to a null address.
            await expect(hubContract.mintSynthAsset("TSLA", 100, ethers.constants.AddressZero))
                .to.be.revertedWith("The address parameter cannot be null");
        });
    });

    describe("BurnSynthAsset", () => {
        it("Should burn synthetic assets", async () => {
            // TODO
        });
    });

    /**************************************** Manage user positions ****************************************/

    describe("IncreaseUserPosition", () => {
        it("Should increase the TSLA position of the user", async () => {
            // TODO
        });
    });

    describe("DecreaseUserPosition", () => {
        it("Should decrease the TSLA position of the user", async () => {
            // TODO
        });
    });

    /**************************************** Getters ****************************************/

    describe("GetUserPositionAmount", () => {
        it("Should return the amount of a specific synthetic asset the user holds", async () => {
            // Check that the TSLA position of the user is empty.
            const tslaPositionAmount = await hubContract.getUserPositionAmount("TSLA", owner.address);
            expect(tslaPositionAmount).to.equal(0);

            // It should fail when getting the position of an empty symbol.
            await expect(hubContract.setSynthAssetAddress("", owner.address))
                .to.be.revertedWith("The symbol parameter cannot be empty");

            // It should fail when getting the position of a null address.
            await expect(hubContract.setSynthAssetAddress("TSLA", ethers.constants.AddressZero))
                .to.be.revertedWith("The address parameter cannot be null");
        });
    });

    describe("GetUserTotalValueMinted", () => {
        it("Should return the value of all the assets minted by the user", async () => {
            // TODO
        });
    });

    describe("GetUserCollateralValue", () => {
        it("Should return the value of the collateral provided by the user", async () => {
            // Set the price tracker address.
            txn = await hubContract.setPriceTrackerAddress(priceTrackerContract.address);
            await txn.wait();

            // Set the collateral fund address.
            txn = await hubContract.setCollateralFundAddress(collateralFundContract.address);
            await txn.wait();

            // Check that the user collateral value is equal to 0.
            let userCollateralValue = await hubContract.getUserCollateralValue(owner.address);
            expect(userCollateralValue).to.equal(0);

            // Provide collateral from the user wallet.
            // 1. Send 100 USDC from the owner wallet to the user wallet.
            txn = await usdcTokenContract.transfer(user.address, 100);
            await txn.wait();

            // 2. Approve the collateral fund to transfer 100 USDC from the user wallet.
            txn = await usdcTokenContract.connect(user).approve(collateralFundContract.address, 100);
            await txn.wait();

            // 3. Send 100 USDC collateral from the user wallet to the fund.
            txn = await collateralFundContract.connect(user).deposit(100);
            await txn.wait();

            // Manipulate the USDC price to set it to 1 USDC = 1 USD.
            txn = await priceTrackerContract.setUsdcPrice(1);
            await txn.wait();

            // Check that the user collateral value is equal to 100.
            userCollateralValue = await hubContract.getUserCollateralValue(user.address);
            expect(userCollateralValue).to.equal(100);
        });
    });

    /**************************************** Setters ****************************************/

    describe("SetCollateralFundAddress", () => {
        it("Should update the collateral fund address", async () => {
            // Update the address.
            const txn = await hubContract.setCollateralFundAddress(collateralFundContract.address);
            await txn.wait();

            // It should fail when updating with a null address.
            await expect(hubContract.setCollateralFundAddress(ethers.constants.AddressZero))
                .to.be.revertedWith("The address parameter cannot be null");

            // It should fail when updating the address as any user.
            await expect(hubContract.connect(user).setCollateralFundAddress(temp.address))
                .to.be.revertedWith("Only the owner can call this method");
        });
    });

    describe("SetPriceTrackerAddress", () => {
        it("Should update the price tracker address", async () => {
            // Update the address.
            const txn = await hubContract.setPriceTrackerAddress(priceTrackerContract.address);
            await txn.wait();

            // It should fail when updating with a null address.
            await expect(hubContract.setPriceTrackerAddress(ethers.constants.AddressZero))
                .to.be.revertedWith("The address parameter cannot be null");

            // It should fail when updating the address as any user.
            await expect(hubContract.connect(user).setPriceTrackerAddress(temp.address))
                .to.be.revertedWith("Only the owner can call this method");
        });
    });

    describe("SetSynthAssetAddress", () => {
        it("Should update the synthetic asset TSLA address", async () => {
            // Update the address.
            const txn = await hubContract.setSynthAssetAddress("TSLA", syntheticTSLAContract.address);
            await txn.wait();

            // It should fail when updating with an empty symbol.
            await expect(hubContract.setSynthAssetAddress("", syntheticTSLAContract.address))
                .to.be.revertedWith("The symbol parameter cannot be empty");

            // It should fail when updating with a null address.
            await expect(hubContract.setSynthAssetAddress("TSLA", ethers.constants.AddressZero))
                .to.be.revertedWith("The address parameter cannot be null");

            // It should fail when updating the address as any user.
            await expect(hubContract.connect(user).setCollateralFundAddress(temp.address))
                .to.be.revertedWith("Only the owner can call this method");
        });
    });
});
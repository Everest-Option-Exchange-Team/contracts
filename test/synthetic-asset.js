const hre = require("hardhat");
const { utils } = require("ethers");
const { expect } = require("chai");

describe("SyntheticAssetV1 smart contract tests", () => {
  let syntheticTSLAContract, owner, user, hub, temp;

  beforeEach(async () => {
    [owner, user, hub, temp] = await hre.ethers.getSigners();

    // Deploy a synthetic TSLA contract.
    const syntheticTSLAContractFactory = await hre.ethers.getContractFactory("SyntheticAssetV1");
    syntheticTSLAContract = await syntheticTSLAContractFactory.deploy("SyntheticTesla", "TSLA", hub.address);
    await syntheticTSLAContract.deployed();
  });

  /**************************************** Mint / Burn ****************************************/

  describe("Mint", () => {
    it("Mint some TSLA synthetic assets", async () => {
      // Check that the owner's synthetic TSLA balance is empty.
      let ownerBalance = await syntheticTSLAContract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(0);

      // Mint 100 synthetic TSLA assets to the owner's wallet.
      let txn = await syntheticTSLAContract.connect(hub).mint(owner.address, 100);
      await txn.wait();

      // Check that the owner is elligible to burn 100 synthetic TSLA assets.
      let amountElligibleToBurn = await syntheticTSLAContract.getAmountEligibleToBurn(owner.address);
      expect(amountElligibleToBurn).to.equal(100);

      // Check that the owner's synthetic TSLA balance is equal to 100.
      ownerBalance = await syntheticTSLAContract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(100);

      // It should fail any other user tries to mint synthetic TSLA assets.
      await expect(syntheticTSLAContract.mint(owner.address, 100))
        .to.be.revertedWith("Only the hub can call this method");

      // It should fail when trying to mint synthetic assets to a null address.
      await expect(syntheticTSLAContract.connect(hub).mint(hre.ethers.constants.AddressZero, 100))
        .to.be.revertedWith("The address parameter cannot be null");

      // It should fail when trying to mint zero synthetic assets.
      await expect(syntheticTSLAContract.connect(hub).mint(owner.address, 0))
        .to.be.revertedWith("Amount should be greator than zero");
    });
  });

  describe("Burn", () => {
    it("Burn some TSLA synthetic assets", async () => {
      // Burn 100 synthetic TSLA assets to the owner's wallet.
      let txn = await syntheticTSLAContract.connect(hub).mint(owner.address, 100);
      await txn.wait();

      // Check that the owner is elligible to burn 100 synthetic TSLA assets.
      let amountElligibleToBurn = await syntheticTSLAContract.getAmountEligibleToBurn(owner.address);
      expect(amountElligibleToBurn).to.equal(100);

      // Check that the owner's synthetic TSLA balance is equal to 100.
      ownerBalance = await syntheticTSLAContract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(100);

      // Burn 40 synthetic TSLA assets from the owner's wallet.
      await syntheticTSLAContract.connect(hub).burn(owner.address, 40);
      await txn.wait();

      // Check that the owner is elligible to burn 60 synthetic TSLA assets.
      amountElligibleToBurn = await syntheticTSLAContract.getAmountEligibleToBurn(owner.address);
      expect(amountElligibleToBurn).to.equal(60);

      // Check that the owner's synthetic TSLA balance is equal to 60.
      ownerBalance = await syntheticTSLAContract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(60);

      // It should fail any other user tries to mint synthetic TSLA assets.
      await expect(syntheticTSLAContract.burn(owner.address, 100))
        .to.be.revertedWith("Only the hub can call this method");

      // It should fail when trying to burn synthetic assets from a null address.
      await expect(syntheticTSLAContract.connect(hub).mint(hre.ethers.constants.AddressZero, 100))
        .to.be.revertedWith("The address parameter cannot be null");

      // It should fail when trying to burn zero synthetic assets.
      await expect(syntheticTSLAContract.connect(hub).burn(owner.address, 0))
        .to.be.revertedWith("Amount should be greator than zero");

      // It should fail when trying to burn more than what the user deposited to the fund.
      await expect(syntheticTSLAContract.connect(hub).burn(owner.address, 100))
        .to.be.revertedWith("The user has not enough assets");
    });
  });

  /**************************************** Getters ****************************************/

  describe("GetAmountEligibleToBurn", () => {
    it("Should return the amount of synthetic asset the user is elligible to burn", async () => {
      // Check that the owner's synthetic TSLA balance is empty.
      let ownerBalance = await syntheticTSLAContract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(0);

      // Check that the owner is elligible to burn zero synthetic TSLA assets.
      let amountElligibleToBurn = await syntheticTSLAContract.getAmountEligibleToBurn(owner.address);
      expect(amountElligibleToBurn).to.equal(0);

      // Mint 100 synthetic TSLA assets to the owner's wallet.
      let txn = await syntheticTSLAContract.connect(hub).mint(owner.address, 100);
      await txn.wait();

      // Check that the owner is elligible to burn 100 synthetic TSLA assets.
      amountElligibleToBurn = await syntheticTSLAContract.getAmountEligibleToBurn(owner.address);
      expect(amountElligibleToBurn).to.equal(100);

      // Check that the owner's synthetic TSLA balance is equal to 100.
      ownerBalance = await syntheticTSLAContract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(100);

      // Burn 40 synthetic TSLA assets from the owner's wallet.
      await syntheticTSLAContract.connect(hub).burn(owner.address, 40);
      await txn.wait();

      // Check that the owner is elligible to burn 60 synthetic TSLA assets.
      amountElligibleToBurn = await syntheticTSLAContract.getAmountEligibleToBurn(owner.address);
      expect(amountElligibleToBurn).to.equal(60);

      // It should fail when trying to get the elligible synthetic asset to burn of a null address.
      await expect(syntheticTSLAContract.connect(hub).getAmountEligibleToBurn(ethers.constants.AddressZero))
        .to.be.revertedWith("The address parameter cannot be null");
    });
  });

  /**************************************** Setters ****************************************/

  describe("SetAmountEligibleToBurn", () => {
    it("Should update the amount of synthetic asset the user is elligible to burn", async () => {
      // Check that the owner's synthetic TSLA balance is empty.
      let ownerBalance = await syntheticTSLAContract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(0);

      // Check that the owner is elligible to burn zero synthetic TSLA assets.
      let amountElligibleToBurn = await syntheticTSLAContract.getAmountEligibleToBurn(owner.address);
      expect(amountElligibleToBurn).to.equal(0);

      // Update the owner's synthetic TSLA balance to 100.
      // Note: this is not how this method is supposed to be used, this method should only be called when
      // the hub has to liquidate a user.
      const txn = await syntheticTSLAContract.connect(hub).setAmountEligibleToBurn(owner.address, 100);
      await txn.wait();

      // Check that the owner is elligible to burn 100 synthetic TSLA assets.
      amountElligibleToBurn = await syntheticTSLAContract.getAmountEligibleToBurn(owner.address);
      expect(amountElligibleToBurn).to.equal(100);

      // Check that the owner's synthetic TSLA balance is equal to 0.
      ownerBalance = await syntheticTSLAContract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(0);

      // It should fail when updating with a null address.
      await expect(syntheticTSLAContract.connect(hub).setAmountEligibleToBurn(ethers.constants.AddressZero, 100))
        .to.be.revertedWith("The address parameter cannot be null");

      // It should fail when updating the collateral amount as any user.
      await expect(syntheticTSLAContract.setAmountEligibleToBurn(user.address, 100))
        .to.be.revertedWith("Only the hub can call this method");
    });
  });

  describe("SetHubAddress", () => {
    it("Should update the hub address", async () => {
      // Update the address.
      const txn = await syntheticTSLAContract.setHubAddress(temp.address);
      await txn.wait();

      // It should fail when updating with a null address.
      await expect(syntheticTSLAContract.setHubAddress(ethers.constants.AddressZero))
        .to.be.revertedWith("The address parameter cannot be null");

      // It should fail when updating the address as any user.
      await expect(syntheticTSLAContract.connect(user).setHubAddress(temp.address))
        .to.be.revertedWith("Only the owner can call this method");
    });
  });

});

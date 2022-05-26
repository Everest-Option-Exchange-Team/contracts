// Deploy and verify the SyntheticAssetV1 contract on the specified network.
// It also handles localhost deployments.
const hre = require("hardhat");
require("dotenv").config();

const { commonConfig, collateralFundConfig } = require("../helper.config");

async function main() {
    // Common parameters.
    const hubAddress = commonConfig.hubAddress;

    const syntheticAssetFactory = await hre.ethers.getContractFactory("SyntheticAssetV1");

    // Deploy the synthetic asset contracts for AAPL, TSLA, MSFT, ABNB and GOOG stocks.
    await deployAndVerify(syntheticAssetFactory, "SyntheticAAPL", "AAPL", hubAddress);
    await deployAndVerify(syntheticAssetFactory, "SyntheticTSLA", "TSLA", hubAddress);
    await deployAndVerify(syntheticAssetFactory, "SyntheticMSFT", "MSFT", hubAddress);
    await deployAndVerify(syntheticAssetFactory, "SyntheticABNB", "ABNB", hubAddress);
    await deployAndVerify(syntheticAssetFactory, "SyntheticGOOG", "GOOG", hubAddress);
}

async function deployAndVerify(synthFactory, name, symbol, hubAddress) {
    const synthContract = await synthFactory.deploy(name, symbol, hubAddress);
    await synthContract.deployed();
    console.log(`${name} contract deployed to ${synthContract.address}`);
    console.log(`Verify with: $ npx hardhat verify ${synthContract.address} ${name} ${symbol} --contract contracts/SyntheticAssetV1.sol:SyntheticAssetV1 --network ${hre.network.name}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

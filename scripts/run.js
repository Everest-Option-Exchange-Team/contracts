const hre = require("hardhat");

const main = async () => {

    console.log("Deploying contract...");
    const contractFactory = await hre.ethers.getContractFactory("Fund");
    const contract = await contractFactory.deploy();
    await contract.deployed();

    console.log("Contract deployed!");

    let funders = await contract.getFunders();
    console.log("funders: ", funders.toString());

}

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

runMain();
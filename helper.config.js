const hre = require("hardhat");

// Parameters used to deploy the PriceTracker smart contract.
const priceTrackerConfig = {
    // Common parameters.
    common: {
        apiKey: process.env.ALPHA_VANTAGE_API_KEY,
        updateInterval: 60, // in seconds.
    },
    
    // Network-specific parameters.
    network: {
        42: { // Kovan testnet.
            linkTokenAddress: hre.ethers.constants.AddressZero,
            aggregatorAddress: "0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60",
            oracleAddress: "0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8",
            // The initial jobId was: d5270d1c311941d0b08bead21fea7747.
            // Converted to bytes32/hex using https://web3-type-converter.onbrn.com/.
            jobId: "0x6435323730643163333131393431643062303862656164323166656137373437",
        },
        43113: { // Fuji testnet.
            linkTokenAddress: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
            // There are no data feeds available for the USDC/USD pair on the Fuji testnet yet.
            // TODO: Find a way to get the USDC/USD price, maybe use the Aplha Vantage API?
            aggregatorAddress: hre.ethers.constants.AddressZero,
            // Since Chainlink does not provide a node to make GET requests on any API on the Fuji testnet,
            // we had to use our custom node. That's why we started working with https://linkwellnodes.io/
            // node operator (custom oracle address and job ID).
            oracleAddress: "0xAc6Fbccc8cFbE2e05C23DFB638f37C838c47760C",
            // The initial jobId was: 70f4f19746e94277a32ddfa0358b8901.
            // Converted to bytes32/hex using https://web3-type-converter.onbrn.com/.
            jobId: "0x3730663466313937343665393432373761333264646661303335386238393031",
        },
    },
};

module.exports = {
    priceTrackerConfig
};

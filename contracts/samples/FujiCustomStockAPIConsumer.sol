// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../StockAPIConsumer.sol";

/**
 * @title Contract that consumes the Alpha Vantage stock price API on the Fuji testnet.
 * @dev It uses linkwellnodes.io node operator.
 * @author The Everest team.
 */
contract FujiCustomStockAPIConsumer is StockAPIConsumer {
    /**
     * @notice Initialise the contract.
     * @param _apiKey the alpha vantage api key.
     * @dev Fuji testnet, LinkWellNodes.io Operator, Alpha Vantage stock price API parameters:
     * Chainlink token address: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846.
     * URL: https://docs.chain.link/docs/link-token-contracts/#avalanche.
     * Oracle address: 0xAc6Fbccc8cFbE2e05C23DFB638f37C838c47760C.
     * Job ID: 70f4f19746e94277a32ddfa0358b8901.
     * URL: https://linkwellnodes.io/
     */
    constructor(string memory _apiKey)
        StockAPIConsumer(
            0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            0xAc6Fbccc8cFbE2e05C23DFB638f37C838c47760C,
            "70f4f19746e94277a32ddfa0358b8901",
            _apiKey
        )
    {}
}
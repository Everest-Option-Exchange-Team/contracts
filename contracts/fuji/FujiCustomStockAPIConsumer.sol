// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../chainlink/StockAPIConsumer.sol";

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
     * Oracle address: CHANGE_ME.
     * Job ID: CHANGE_ME.
     * URL: https://linkwellnodes.io/
     */
    constructor(string memory _apiKey)
        StockAPIConsumer(
            CHANGE_ME,
            "CHANGE_ME",
            _apiKey
        )
    {}
}

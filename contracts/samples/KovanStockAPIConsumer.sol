// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../StockAPIConsumer.sol";

/**
 * @title Contract that consumes the Alpha Vantage stock price API on the Kovan testnet.
 * @dev It uses Chainlink node operator.
 * @author The Everest team.
 */
contract KovanStockAPIConsumer is StockAPIConsumer {
    /**
     * @notice Initialise the contract.
     * @param _apiKey the alpha vantage api key.
     * @dev Kovan testnet, Chainlink Operator, Alpha Vantage stock price API parameters:
     * Oracle address: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8.
     * Job ID: d5270d1c311941d0b08bead21fea7747.
     * URL: https://docs.chain.link/docs/decentralized-oracles-ethereum-mainnet/
     */
    constructor(string memory _apiKey)
        StockAPIConsumer(
            address(0),
            0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8,
            "d5270d1c311941d0b08bead21fea7747",
            _apiKey
        )
    {}
}

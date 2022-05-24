// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Storage.sol";

/**
 * @title Contract that consumes the Alpha Vantage stock price API on the Kovan testnet.
 * @dev It uses Chainlink node operator.
 * @author The Everest team.
 */
contract KovanStorage is Storage {
    /**
     * @notice Initialise the contract.
     * @param _apiKey the alpha vantage api key.
     * @param _updateInterval the update interval of the supported asset prices (in seconds).
     * @dev Chainlink parameters for Kovan testnet.
     *
     * 1) Kovan tesnet, Chainlink Aggregator USDC/USD:
     * Aggregator address: 0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60
     * 
     * 2) Kovan testnet, Chainlink Operator, Alpha Vantage stock price API parameters:
     * Oracle address: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8.
     * Job ID: d5270d1c311941d0b08bead21fea7747.
     * URL: https://docs.chain.link/docs/decentralized-oracles-ethereum-mainnet/
     */
    constructor(string memory _apiKey, uint256 _updateInterval)
        Storage(
            address(0),
            0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60,
            0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8,
            "d5270d1c311941d0b08bead21fea7747",
            _apiKey,
            _updateInterval
        )
    {}
}

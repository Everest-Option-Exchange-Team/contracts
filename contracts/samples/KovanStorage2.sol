// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Storage.sol";

/**
 * @title Contract that consumes the Alpha Vantage stock price API on the Kovan testnet.
 * @dev It uses linkwellnodes.io node operator.
 * @author The Everest team.
 */
contract KovanStorage2 is Storage {
    /**
     * @notice Initialise the contract.
     * @param _apiKey the alpha vantage api key.
     * @param _updateInterval the update interval of the supported asset prices (in seconds).
     * @dev Chainlink parameters for Kovan testnet.
     *
     * 1) Kovan tesnet, Chainlink Aggregator USDC/USD:
     * Aggregator address: 0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60
     *
     * 2) Kovan testnet, LinkWellNodes.io Operator, Alpha Vantage stock price API parameters:
     * Oracle address: 0xd39E4aC9b2d46D27109697651b1510063Ac50840.
     * Job ID: 84c8b85a04fa4b398407879fae6052e6.
     * URL: https://linkwellnodes.io/
     */
    constructor(string memory _apiKey, uint256 _updateInterval)
        Storage(
            address(0),
            0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60,
            0xd39E4aC9b2d46D27109697651b1510063Ac50840,
            "84c8b85a04fa4b398407879fae6052e6",
            _apiKey,
            _updateInterval
        )
    {}
}

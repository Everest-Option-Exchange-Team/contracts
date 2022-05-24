// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Storage.sol";

/**
 * @title Contract that consumes the Alpha Vantage stock price API on the Fuji testnet.
 * @dev It uses linkwellnodes.io node operator.
 * @author The Everest team.
 */
contract FujiStorage is Storage {
    /**
     * @notice Initialise the contract.
     * @param _apiKey the alpha vantage api key.
     * @param _updateInterval the update interval of the supported asset prices (in seconds).
     * @dev Chainlink parameters for Fuji testnet.
     *
     * 1) No aggregator address for the USDC/USD price feed. :(
     * TODO: we should try to get the price from the Alpha Vantage API.
     *
     * 2) Fuji testnet, LinkWellNodes.io Operator, Alpha Vantage stock price API parameters:
     * Chainlink token address: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846.
     * URL: https://docs.chain.link/docs/link-token-contracts/#avalanche.
     * Oracle address: 0xAc6Fbccc8cFbE2e05C23DFB638f37C838c47760C.
     * Job ID: 70f4f19746e94277a32ddfa0358b8901.
     * URL: https://linkwellnodes.io/
     */
    constructor(string memory _apiKey, uint256 _updateInterval)
        Storage(
            0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            address(0),
            0xAc6Fbccc8cFbE2e05C23DFB638f37C838c47760C,
            "70f4f19746e94277a32ddfa0358b8901",
            _apiKey,
            _updateInterval
        )
    {}
}

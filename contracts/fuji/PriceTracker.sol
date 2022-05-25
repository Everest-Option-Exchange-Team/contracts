// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../base/BasePriceTracker.sol";

/**
 * @title Contract that retrieves USDC and asset prices on the Fuji testnet.
 * @dev Since Chainlink does not provide a node to make GET requests on any API on the Fuji testnet,
 * we had to use our custom node. That's why we started working with https://linkwellnodes.io/ node operator.
 * @author The Everest team.
 */
 //slither-disable-next-line name-reused
contract PriceTracker is BasePriceTracker {
    /**
     * @notice Initialise the contract.
     * @param _apiKey the alpha vantage api key.
     * @param _updateInterval the update interval of the supported asset prices (in seconds).
     * @dev Chainlink Fuji parameters:
     * - Chainlink token address: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846.
     * - USDC/USD aggregator address: No data feeds available for this pair on this network yet.
     *   TODO: Find a way to get the USDC/USD price on Fuji testnet, maybe use the Alpha Vantage API?
     * - Custom node address: 0xAc6Fbccc8cFbE2e05C23DFB638f37C838c47760C.
     * - Custom job ID to make GET requests: 70f4f19746e94277a32ddfa0358b8901.
     */
    constructor(string memory _apiKey, uint256 _updateInterval)
        BasePriceTracker(
            0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            address(0),
            0xAc6Fbccc8cFbE2e05C23DFB638f37C838c47760C,
            "70f4f19746e94277a32ddfa0358b8901",
            _apiKey,
            _updateInterval
        )
    {}
}

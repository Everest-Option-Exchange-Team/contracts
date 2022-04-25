// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../chainlink/DataFeed.sol";

/**
 * @title Contract which returns the last price of AVAX/USD on the Fuji testnet.
 * @author The Everest team.
 */
contract FujiAvaxFeed is DataFeed {
    /**
     * @notice Initialise the contract.
     * @dev Fuji testnet AVAX/USD aggregator parameters:
     * Aggregator address: 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD.
     * URL: https://docs.chain.link/docs/avalanche-price-feeds/.
     */
    constructor() DataFeed(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD) {}
}

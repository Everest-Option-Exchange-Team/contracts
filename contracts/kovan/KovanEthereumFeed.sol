// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../chainlink/DataFeed.sol";

/**
 * @title Contract which returns the last price of ETH/USD on the Kovan testnet.
 * @author The Everest team.
 */
contract KovanEthereumFeed is DataFeed {
    /**
     * @notice Initialise the contract.
     * @dev Kovan testnet ETH/USD aggregator parameters:
     * Aggregator address: 0x9326BFA02ADD2366b30bacB125260Af641031331.
     * URL: https://docs.chain.link/docs/ethereum-addresses/.
     */
    constructor() DataFeed(0x9326BFA02ADD2366b30bacB125260Af641031331) {}
}

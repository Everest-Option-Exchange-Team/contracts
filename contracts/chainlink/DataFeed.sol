// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Generic contract which returns the last price of any asset supported by Chainlink Data Feeds.
 * @author The Everest team.
 */
contract DataFeed {
    AggregatorV3Interface internal priceFeed;

    /**
     * @notice Initialise the contract.
     * @param _addr the aggregator interface.
     */
    constructor(address _addr) {
        priceFeed = AggregatorV3Interface(_addr);
    }

    /**
     * @notice Returns the latest price
     * @return the latest price.
     */
    function getLatestPrice() public view returns (int256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Generic contract which returns the last price of any asset supported by Chainlink Data Feeds.
 * @author The Everest team.
 */
contract DataFeed {
    address public owner;
    AggregatorV3Interface internal priceFeed;

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    event PriceFeedAddressUpdated();

    /**
     * @notice Initialise the contract.
     * @param _addr the aggregator address.
     */
    constructor(address _addr) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_addr);
    }

    /**
     * @notice Returns the latest price
     * @return the latest price.
     */
    function getLatestPrice() external view returns (int256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @notice Update the price feed.
     * @param _addr the new aggregator address.
     */
    function updatePriceFeed(address _addr) external onlyOwner {
        priceFeed = AggregatorV3Interface(_addr);
        emit PriceFeedAddressUpdated();
    }
}

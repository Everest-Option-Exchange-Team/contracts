// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../base/BasePriceTracker.sol";

/**
 * @title Contract that retrieves USDC and asset prices on the Kovan testnet.
 * @author The Everest team.
 */
contract PriceTracker is BasePriceTracker {
    /**
     * @notice Initialise the contract.
     * @param _apiKey the alpha vantage api key.
     * @param _updateInterval the update interval of the supported asset prices (in seconds).
     * @dev Chainlink Kovan parameters:
     * - Chainlink token address: No need to specify on Kovan, the address is registered automatically.
     * - USDC/USD aggregator address: 0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60.
     * - Chainlink node address: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8.
     * - Chainlink job ID to make GET requests: d5270d1c311941d0b08bead21fea7747.
     */
    constructor(string memory _apiKey, uint256 _updateInterval)
        BasePriceTracker(
            address(0),
            0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60,
            0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8,
            "d5270d1c311941d0b08bead21fea7747",
            _apiKey,
            _updateInterval
        )
    {}
}

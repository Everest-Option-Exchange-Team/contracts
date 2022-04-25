// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title Contract that consumes the Alpha Vantage stock price API.
 * @dev https://market.link/adapters/30861015-8da4-4f24-a76b-20efaf199e28.
 * @author The Everest team.
 */
contract APIConsumer is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    // Kovan network parameters.
    // https://docs.chain.link/docs/decentralized-oracles-ethereum-mainnet/
    address constant private ORACLE_ADDRESS = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
    bytes32 constant private JOB_ID = "d5270d1c311941d0b08bead21fea7747";
    uint256 constant private ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY;
    
    mapping(bytes32 => string) private requestIdToStock;
    mapping(string => uint256) public stockToPrices;
    address public owner;
    string private apiKey;

    event PriceUpdated(bytes32 indexed requestId, uint256 price);
    event ApiKeyUpdated();
    event Withdraw(address indexed addr, uint256 amount);

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    /**
     * @notice Initialise the contract.
     * @param _apiKey the alpha vantage api key.
     */
    constructor(string memory _apiKey) {
        setPublicChainlinkToken();
        owner = msg.sender;
        apiKey = _apiKey;
    }
    
    /**
     * @notice Request stock price from the API.
     * @dev It uses the Alpha Vantage API.
     */
    //slither-disable-next-line naming-convention
    function requestPrice(string memory _stock) external onlyOwner returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(JOB_ID, address(this), this.fulfill.selector);
        string memory url = string(abi.encodePacked(
            "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=",
            _stock,
            "&apikey=",
            apiKey
        ));
        req.add("get", url);
        string[] memory path = new string[](2);
        path[0] = "Global Quote";
        path[1] = "05. price";
        req.addStringArray("path", path);
        req.addInt("times", 100);
        requestIdToStock[requestId] = _stock;
        return sendChainlinkRequestTo(ORACLE_ADDRESS, req, ORACLE_PAYMENT);
    }

    /**
     * @notice Callback function that updates the stock price stored in the contract.
     * @param _requestId the id of the Chainlink request.
     * @param _price the new stock price.
     */
    //slither-disable-next-line naming-convention
    function fulfill(bytes32 _requestId, uint256 _price) external recordChainlinkFulfillment(_requestId) {
        string memory stock = requestIdToStock[_requestId];
    	stockToPrices[stock] = _price;
        emit PriceUpdated(_requestId, _price);
    }

    /**
     * @notice Update the alpha vantage api key.
     * @param _apiKey the new api key.
     */
    //slither-disable-next-line naming-convention
    function updateApiKey(string memory _apiKey) external onlyOwner {
        apiKey = _apiKey;
        emit ApiKeyUpdated();
    }

    /**
     * @notice Withdraw all the contract funds to the owner wallet.
     * @dev Avoid locking LINK tokens in the contract.
     */
    function withdraw() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}

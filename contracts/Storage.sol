// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title Storage contract that retrieves asset prices.
 * @dev It consumes the Alpha Vantage asset price API using Chainlink Data Feeds.
 * See the external adapter on the market: https://market.link/adapters/30861015-8da4-4f24-a76b-20efaf199e28.
 * @author The Everest team.
 */
contract Storage is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    uint256 constant private FEE = 0.1 * 10 ** 18; // 0.1 LINK
    address public owner;
    address internal oracleAddress;
    bytes32 internal jobId;
    string private apiKey;

    struct Asset {
        uint256 price;
        bool exists;
    }

    mapping(bytes32 => string) private requestIdToAsset;
    mapping(string => Asset) public assetToPrice;
    string[] public assetList;

    event PriceUpdated(bytes32 indexed requestId, uint256 price);
    event OracleAddressUpdated();
    event JobIDUpdated();
    event ApiKeyUpdated();
    event Withdraw(address indexed addr, uint256 amount);

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    modifier assetExists(string memory _asset) {
        require(assetToPrice[_asset].exists);
        _;
    }

    /**
     * @notice Initialise the contract.
     * @param _linkAddress the address of the link token contract.
     * @param _oracleAddress the address of the chainlink node operator.
     * @param _jobId the id of the job.
     * @param _apiKey the alpha vantage api key.
     */
    constructor(address _linkAddress, address _oracleAddress, bytes32 _jobId, string memory _apiKey) {
        if (_linkAddress == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_linkAddress);
        }

        owner = msg.sender;
        oracleAddress = _oracleAddress;
        jobId = _jobId;
        apiKey = _apiKey;
    }

    /**
     * @notice Add an asset to the list of supported assets.
     * @param _asset the asset name.
     */
    function addAsset(string memory _asset) external onlyOwner assetExists(_asset) {
        assetList.push(_asset);
        assetToPrice[_asset].exists = true;
    }
    
    /**
     * @notice Return the price of an asset.
     * @dev The asset must be supported by the contract.
     * @param _asset the asset name.
     * @return _ the price of the asset.
     */
    function getAssetPrice(string memory _asset) external view assetExists(_asset) returns (uint256) {
        return assetToPrice[_asset].price;
    }

    /**
     * @notice Return the list of supported assets.
     * @return _ the list of supported assets.
     */
    function getAssetList() external view returns (string[] memory) {
        return assetList;
    }

    /**
     * @notice Update the asset price using the Alpha Vantage API.
     * @param _asset the asset name.
     $ @return requestId the id of the Chainlink request.
     */
    function updateAssetPrice(string memory _asset) external onlyOwner assetExists(_asset) returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        string memory url = string(abi.encodePacked(
            "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=",
            _asset,
            "&apikey=",
            apiKey
        ));
        req.add("get", url);
        string[] memory path = new string[](2);
        path[0] = "Global Quote";
        path[1] = "05. price";
        req.addStringArray("path", path);
        req.addInt("times", 100);
        requestId = sendChainlinkRequestTo(oracleAddress, req, FEE);
        requestIdToAsset[requestId] = _asset;
    }

    /**
     * @notice Callback function that updates the asset price stored in the contract.
     * @param _requestId the id of the Chainlink request.
     * @param _price the new asset price.
     */
    function fulfill(bytes32 _requestId, uint256 _price) external recordChainlinkFulfillment(_requestId) {
        string memory asset = requestIdToAsset[_requestId];
    	assetToPrice[asset].price = _price;
        emit PriceUpdated(_requestId, _price);
    }

    /**
     * @notice Update the oracle address.
     * @param _oracleAddress the new chainlink node operator address.
     */
    function updateOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
        emit OracleAddressUpdated();
    }

    /**
     * @notice Update the job ID.
     * @param _jobId the new job ID.
     */
    function updateJobId(bytes32 _jobId) external onlyOwner {
        jobId = _jobId;
        emit JobIDUpdated();
    }

    /**
     * @notice Update the alpha vantage api key.
     * @param _apiKey the new api key.
     */
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

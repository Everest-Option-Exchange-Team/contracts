// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

/**
 * @title Storage contract that retrieves asset prices.
 * @dev It consumes the Alpha Vantage asset price API using Chainlink Data Feeds.
 * See the external adapter on the market: https://market.link/adapters/30861015-8da4-4f24-a76b-20efaf199e28.
 * @dev The supported asset prices are updated every {_updateInterval} seconds using Chainlink Keepers.
 * To make it work, the contract must be registered as an Unkeep on the Keepers Registry after its deployment.
 * See: https://docs.chain.link/docs/chainlink-keepers/register-upkeep/.
 * @author The Everest team.
 */
contract Storage is ChainlinkClient, KeeperCompatibleInterface {
    using Chainlink for Chainlink.Request;

    // Chainlink external adapter parameters.
    uint256 constant private FEE = 0.1 * 10 ** 18; // 0.1 LINK
    address public owner;
    address internal oracleAddress;
    bytes32 internal jobId;
    string private apiKey;

    // Chainlink keepers parameters.
    uint public immutable interval;
    uint public lastTimeStamp;

    struct Asset {
        uint256 price;
        bool exists;
    }

    // Asset parameters.
    mapping(bytes32 => string) private requestIdToAsset;
    mapping(string => Asset) public assetToPrice;
    string[] public assetList;

    // Access-control parameters.
    address public hubAddress;
    address public keepersRegistryAddress;

    // Events
    event PriceUpdated(bytes32 indexed requestId, uint256 price);
    event Withdraw(address indexed addr, uint256 amount);
    event HubAddressUpdated(address oldAddress, address newAddress);
    event KeepersRegistryAddressUpdated(address oldAddress, address newAddress);
    event OracleAddressUpdated(address oldAddress, address newAddress);
    event JobIDUpdated(bytes32 oldId, bytes32 newId);
    event ApiKeyUpdated(string oldApiKey, string newApiKey);

    // Modifiers
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    /**
     * @notice Initialise the contract.
     * @param _linkAddress the address of the link token contract.
     * @param _oracleAddress the address of the chainlink node operator.
     * @param _jobId the id of the job.
     * @param _apiKey the alpha vantage api key.
     * @param _updateInterval the update interval of the supported asset prices (in seconds).
     */
    constructor(address _linkAddress, address _oracleAddress, bytes32 _jobId, string memory _apiKey, uint256 _updateInterval) {
        if (_linkAddress == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_linkAddress);
        }

        // Chainlink external adapter parameters.
        owner = msg.sender;
        oracleAddress = _oracleAddress;
        jobId = _jobId;
        apiKey = _apiKey;

        // Chainlink keepers parameters.
        interval = _updateInterval;
        lastTimeStamp = block.timestamp;
    }

    /**
     * @notice Add an asset to the list of supported assets.
     * @param _asset the asset name.
     * @dev The method can only be called by the hub or the owner.
     */
    function addAsset(string memory _asset) external {
        require(msg.sender == hubAddress || msg.sender == owner);
        require(!assetToPrice[_asset].exists);

        assetList.push(_asset);
        assetToPrice[_asset].exists = true;
    }

    /**
     * @notice Withdraw all the contract funds to the owner wallet.
     * @dev Avoid locking LINK tokens in the contract.
     */
    function withdraw() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    /**************************************** ChainLink External Adapters ****************************************/

    /**
     * @notice Update the asset price using the Alpha Vantage API.
     * @param _asset the asset name.
     $ @return requestId the id of the Chainlink request.
     * @dev The method can only be called by the keepers registry or the owner.
     */
    function updateAssetPrice(string memory _asset) public returns (bytes32 requestId) {
        require(msg.sender == keepersRegistryAddress || msg.sender == owner);
        require(assetToPrice[_asset].exists);

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

    /**************************************** ChainLink Keepers ****************************************/

    /**
     * @notice Check if the performUpkeep function should be executed.
     * @dev See the Chainlink Keepers documentation: https://docs.chain.link/docs/chainlink-keepers/compatible-contracts/.
     * @return _ boolean that when true, will trigger the on-chain performUpkeep call.
     * @return _ bytes that will be used as input parameter when calling performUpkeep (here empty).
     */
    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
        return((block.timestamp - lastTimeStamp) > interval, abi.encode('0x'));
    }

    /**
     * @notice Update the price of all the supported assets.
     * @dev Function triggered when checkUpkeep function returns upkeepNeeded == true.
     */
    function performUpkeep(bytes calldata) external override {
        // Re-validate the upkeep condition.
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            
            // Update the price of all the supported assets.
            for (uint256 i = 0; i < assetList.length; i++) {
                updateAssetPrice(assetList[i]);
            }
        }
    }

    /**************************************** Getters ****************************************/

    /**
     * @notice Return the list of supported assets.
     * @return _ the list of supported assets.
     */
    function getAssetList() external view returns (string[] memory) {
        return assetList;
    }

    /**************************************** Setters ****************************************/

    /**
     * @notice Update the hub address.
     * @param _hubAddress the new hub address.
     */
    function setHubAddress(address _hubAddress) external onlyOwner {
        emit HubAddressUpdated(hubAddress, _hubAddress);
        hubAddress = _hubAddress;
    }

    /**
     * @notice Update the keepers registry address.
     * @param _keepersRegistryAddress the new keepers registry address.
     */
    function setKeepersRegistryAddress(address _keepersRegistryAddress) external onlyOwner {
        emit KeepersRegistryAddressUpdated(keepersRegistryAddress, _keepersRegistryAddress);
        keepersRegistryAddress = _keepersRegistryAddress;
    }

    /**
     * @notice Update the oracle address.
     * @param _oracleAddress the new chainlink node operator address.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        emit OracleAddressUpdated(oracleAddress, _oracleAddress);
        oracleAddress = _oracleAddress;
    }

    /**
     * @notice Update the job ID.
     * @param _jobId the new job ID.
     */
    function setJobId(bytes32 _jobId) external onlyOwner {
        emit JobIDUpdated(jobId, _jobId);
        jobId = _jobId;
    }

    /**
     * @notice Update the alpha vantage api key.
     * @param _apiKey the new api key.
     */
    function setApiKey(string memory _apiKey) external onlyOwner {
        emit ApiKeyUpdated(apiKey, _apiKey);
        apiKey = _apiKey;
    }
}

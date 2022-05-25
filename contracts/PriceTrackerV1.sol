// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

/**
 * @title PriceTrackerV1 contract that retrieves USDC and asset prices.
 * @dev The contract uses multiple oracle Chainlink products to expose the most reliable data possible.
 * Of course, the ideal would be to diversify the sources and thus to explore the possibilities of other
 * oracles but that was well beyond the scope of the hackathon.
 * To summarize, the contract is based on:
 * - Chainlink Data Feeds to obtain the price of the USDC/USD pair.
 * - Chainlink External Adapters and the Alpha Vantage API  to obtain the USD price of assets (stocks, commodities, etc.).
 * - Chainlnk Keepers to update the prices periodically.
 * @author The Everest team.
 */
contract PriceTrackerV1 is ChainlinkClient, KeeperCompatibleInterface {
    using Chainlink for Chainlink.Request;

    // Chainlink data feeds parameters.
    AggregatorV3Interface internal usdcPriceFeed;

    // Chainlink external adapter parameters.
    uint256 constant private FEE = 0.1 * 10 ** 18; // 0.1 LINK
    address public owner;
    address internal oracleAddress;
    bytes32 internal jobId;
    string private apiKey;

    // Chainlink keepers parameters.
    uint public immutable interval;
    uint public lastTimeStamp;

    // USDC price parameter.
    int256 usdcPrice;

    // Asset parameters.
    struct Asset {
        uint256 price;
        bool exists;
    }

    mapping(bytes32 => string) private requestIdToAsset;
    mapping(string => Asset) public assetToPrice;
    string[] public assetList;

    // Access-control parameters.
    address public hubAddress;
    address public aggregatorAddress;
    address public keepersRegistryAddress;

    // Pause parameter.
    bool public paused;

    // Events
    event PriceUpdated(bytes32 indexed requestId, uint256 price);
    event Paused();
    event Unpaused();
    event Withdraw(address indexed addr, uint256 amount);
    event HubAddressUpdated(address oldAddress, address newAddress);
    event AggregatorAddressUpdated(address oldAddress, address newAddress);
    event KeepersRegistryAddressUpdated(address oldAddress, address newAddress);
    event OracleAddressUpdated(address oldAddress, address newAddress);
    event JobIDUpdated(bytes32 oldId, bytes32 newId);
    event ApiKeyUpdated(string oldApiKey, string newApiKey);

    // Modifiers
    modifier onlyOwner() {
        require (msg.sender == owner, "Only the owner can call this method");
        _;
    }

    /**
     * @notice Initialise the contract.
     * @param _linkAddress the address of the link token contract.
     * @param _aggregatorAddress the address of the USDC/USD aggregator.
     * @param _oracleAddress the address of the chainlink node operator.
     * @param _jobId the id of the job (it has to be written between quotes!).
     * @param _apiKey the alpha vantage api key.
     * @param _updateInterval the update interval of the supported asset prices (in seconds).
     */
    constructor(address _linkAddress, address _aggregatorAddress, address _oracleAddress, bytes32 _jobId, string memory _apiKey, uint256 _updateInterval) {
        require(_aggregatorAddress != address(0), "The aggregator address cannot be null");
        require(_oracleAddress != address(0), "The oracle address cannot be null");
        require(_jobId.length > 0, "The job ID cannot be empty");
        require(bytes(_apiKey).length > 0, "The API key cannot be empty");
        require(_updateInterval > 0, "The update interval cannot be equal to zero");
        
        owner = msg.sender;

        // Link token address.
        if (_linkAddress == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_linkAddress);
        }

        // Chainlink data feeds parameters.
        aggregatorAddress = _aggregatorAddress;
        usdcPriceFeed = AggregatorV3Interface(_aggregatorAddress);

        // Chainlink external adapter parameters.
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
     //slither-disable-next-line naming-convention
    function addAsset(string memory _asset) external {
        require(msg.sender == hubAddress || msg.sender == owner, "Only the hub and the owner can call this method");
        require(bytes(_asset).length > 0, "The asset name cannot be empty");
        require(!assetToPrice[_asset].exists, "The asset must not already be registered in the contract");

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

    /**************************************** ChainLink Data Feeds ****************************************/

    /**
     * @notice Update the USDC/USD price using Chainlink Data Feeds.
     * @dev The method can only be called by the keepers registry or the owner.
     */
    function updateUSDCPrice() public {
        require(msg.sender == keepersRegistryAddress || msg.sender == owner, "Only the keepers registry and the owner can call this method");

        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = usdcPriceFeed.latestRoundData();
        usdcPrice = price;
    }

    /**************************************** ChainLink External Adapters ****************************************/

    /**
     * @notice Update the asset price using the Alpha Vantage API.
     * @param _asset the asset name.
     $ @return requestId the id of the Chainlink request.
     * @dev
     * - The method can only be called by the keepers registry or the owner.
     * - The last line of the method is detected as a reentrancy bug by Slither but it's not critical.
     *   It would act as a double call wich would simply update twice the asset price.
     */
     //slither-disable-next-line naming-convention
    function updateAssetPrice(string memory _asset) public returns (bytes32 requestId) {
        require(msg.sender == keepersRegistryAddress || msg.sender == owner, "Only the keepers registry and the owner can call this method");
        require(bytes(_asset).length > 0, "The asset name cannot be empty");
        require(assetToPrice[_asset].exists, "The asset must already be registered in the contract");

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
     //slither-disable-next-line naming-convention
    function fulfill(bytes32 _requestId, uint256 _price) external recordChainlinkFulfillment(_requestId) {
        string memory asset = requestIdToAsset[_requestId];
    	assetToPrice[asset].price = _price;
        emit PriceUpdated(_requestId, _price);
    }

    /**************************************** ChainLink Keepers ****************************************/

    /**
     * @notice Check if the performUpkeep function should be executed.
     * @return _ boolean that when true, will trigger the on-chain performUpkeep call.
     * @return _ bytes that will be used as input parameter when calling performUpkeep (here empty).
     * @dev Timestamps are used for comparison which is not optimal because it can be manipulated by miners.
     * However, this is not a critical method, it can't be exploited and it should only be called by the
     * keepers registry or the owner.
     */
    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
        require(!paused, "The contract is paused and the automatic update of prices is stopped");
        return((block.timestamp - lastTimeStamp) > interval, abi.encode('0x'));
    }

    /**
     * @notice Update the price of all the supported assets.
     * @dev
     * - The method can only be called by the keepers registry or the owner.
     * - The method is triggered when the checkUpkeep function returns true.
     * - Timestamps are used for comparison which is not optimal because it can be manipulated by miners.
     *   However, this is not a critical method, it can't be exploited and it should only be called by the
     *   keepers registry or the owner.
     */
    function performUpkeep(bytes calldata) external override {
        require(msg.sender == keepersRegistryAddress || msg.sender == owner, "Only the keepers registry and the owner can call this method");
        
        // Re-validate the upkeep condition.
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;

            // Update the USDC/USD price.
            updateUSDCPrice();
            
            // Update the price of all the supported assets.
            for (uint256 i = 0; i < assetList.length; i++) {
                updateAssetPrice(assetList[i]);
            }
        }
    }

    /**************************************** Pause / Unpause ****************************************/

    /**
     * @notice Pause the contract: prices won't be updated by Chainlink keepers until
     * the contract is unpaused by the owner.
     * @dev Prices can still be updated manually by the owner.
     */
    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    /**
     * @notice Unpause the contract: prices will now be updated by Chainlink keepers until
     * the contract is paused by the owner.
     */
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    /**************************************** Getters ****************************************/

    /**
     * @notice Return the USDC/USD price.
     * @return _ the price of USDC in USD.
     */
    function getUSDCPrice() external view returns (int256) {
        return usdcPrice;
    }

    /**
     * @notice Return the price of an asset.
     * @param _asset the asset name.
     * @return _ the price of the asset.
     */
     //slither-disable-next-line naming-convention
    function getAssetPrice(string memory _asset) external view returns (uint256) {
        require(bytes(_asset).length > 0, "The asset name cannot be empty");
        require(assetToPrice[_asset].exists, "The asset must already be registered in the contract");
        
        return assetToPrice[_asset].price;
    }

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
     //slither-disable-next-line naming-convention
    function setHubAddress(address _hubAddress) external onlyOwner {
        require(_hubAddress != address(0), "The hub address cannot be null");

        emit HubAddressUpdated(hubAddress, _hubAddress);
        hubAddress = _hubAddress;
    }

    /**
     * @notice Update the aggregator address and the USDC/USD price feed.
     * @param _aggregatorAddress the new USDC/USD aggregator address.
     */
     //slither-disable-next-line naming-convention
    function setAggregatorAddress(address _aggregatorAddress) external onlyOwner {
        require(_aggregatorAddress != address(0), "The aggregator address cannot be null");

        emit AggregatorAddressUpdated(aggregatorAddress, _aggregatorAddress);
        aggregatorAddress = _aggregatorAddress;
        usdcPriceFeed = AggregatorV3Interface(_aggregatorAddress);
    }

    /**
     * @notice Update the keepers registry address.
     * @param _keepersRegistryAddress the new keepers registry address.
     */
     //slither-disable-next-line naming-convention
    function setKeepersRegistryAddress(address _keepersRegistryAddress) external onlyOwner {
        require(_keepersRegistryAddress != address(0), "The keepers registry address cannot be null");

        emit KeepersRegistryAddressUpdated(keepersRegistryAddress, _keepersRegistryAddress);
        keepersRegistryAddress = _keepersRegistryAddress;
    }

    /**
     * @notice Update the oracle address.
     * @param _oracleAddress the new chainlink node operator address.
     */
     //slither-disable-next-line naming-convention
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "The oracle address cannot be null");

        emit OracleAddressUpdated(oracleAddress, _oracleAddress);
        oracleAddress = _oracleAddress;
    }

    /**
     * @notice Update the job ID.
     * @param _jobId the new job ID.
     */
     //slither-disable-next-line naming-convention
    function setJobId(bytes32 _jobId) external onlyOwner {
        require(_jobId.length > 0, "The job ID cannot be empty");

        emit JobIDUpdated(jobId, _jobId);
        jobId = _jobId;
    }

    /**
     * @notice Update the alpha vantage api key.
     * @param _apiKey the new api key.
     */
     //slither-disable-next-line naming-convention
    function setApiKey(string memory _apiKey) external onlyOwner {
        require(bytes(_apiKey).length > 0, "The API key cannot be empty");

        emit ApiKeyUpdated(apiKey, _apiKey);
        apiKey = _apiKey;
    }
}

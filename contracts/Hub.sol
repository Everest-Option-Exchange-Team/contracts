// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Hub Contract that coordinates Storage, Fund and Minter contract.
 * @dev The contract can mint new synthtic assets (erc20 token), check the collateral ratio of addresses
 * and liquidate addresses if the collateral ratio falls below 150%
 * @author The Everest team.
 */

contract Hub is Ownable {
    // Contract addresses
    ICollateralFunds private fundContract;
    IStorage private storageContract;
    IUniswapV3Factory private factory;

    address[] private authorizedAddresses;
    mapping(string => address) private tickersymbolToSynthContractAddress;
    mapping(string => address) private tickerSymbolToTradingPool;

    address USDCAddressEthereum = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48;
    address uniswapV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;



    modifier onlyAuthorizedAddresses() {
        bool isAuthorized = false;
        for(uint i = 0; i < authorizedAddresses.length; i++) {
            if(authorizedAddresses[i] == msg.sender) {
                isAuthorized = true;
            }
        }
        require(isAuthorized);
        _;
    }

    constructor() {
    }

    /**
     * @notice Add an address to the list of authorized addresses
     * @param addr address that gets added 
     */
    function addAuthorizedAddress(address addr) public onlyOwner{
        authorizedAddresses.push(addr);
    }


    /**
     * @notice mints synthAssets to a specific address
     * @param receiver address to which token gets minted
     * @param amount amount of token that gets minted
     * @param tickerSymbol identifier of which token gets minted
     */
    function mintSynthAsset(address receiver, uint256 amount, string memory tickerSymbol) public onlyAuthorizedAddresses{
        ISyntheticAsset(tickersymbolToSynthContractAddress[tickerSymbol]).mint(receiver, amount); 
    }

    /**
     * @notice sets the Minter contract address
     * @param _minterAddress address of Minter contract
     */
    function setMinterContractAddress(address _minterAddress, string memory tickerSymbol) public onlyOwner{
        tickersymbolToSynthContractAddress[tickerSymbol] = _minterAddress;
    }

    /**
     * @notice sets the Fund contract address
     * @param _fundAddress address of Fund contract
     */
    function setCollateralFundsContract(address _fundAddress) public onlyOwner{
        fundContract = ICollateralFunds(_fundAddress);
    }

    /**
     * @notice sets the Storage contract address
     * @param _storageAddress address of Storage contract
     */
    function setStorageContract(address _storageAddress) public onlyOwner{
        storageContract = IStorage(_storageAddress);
    }

    /**
     * @notice checks the collateral ratio of an address.
     * @dev for all assets combined. No individual / isolated positions for now.
     * @dev price checking of colllateral too -> volatile collateral / depegging of stable collateral
     * @param addr address of user whom collateral ratio is to be checked.
     * @param collateralTickerSymbol identifier of token used for collateral#
     * @return collateral ratio
     */
        function getCollateralRatioByAddress(address addr, string memory collateralTickerSymbol) public view returns (uint256) {
         
         //Check amount funded
         uint256 amountFunded = fundContract.getCollateralByAddress(msg.sender);
         uint256 collateralPrice = storageContract.getAssetPrice(collateralTickerSymbol);
         uint256 collateralValue = amountFunded * collateralPrice;

         //Check assets minted
         string[] memory assetsMinted = storageContract.getAssetListOfUser(addr);
         // Total value of minted assets
         uint256 totalValueMinted = 0;
         //Sum up total value of minted assets
         for(uint i = 0; i < assetsMinted.length; i++) {
             uint256 assetAmount = storageContract.getAssetAmountOfUser(addr, assetsMinted[i]);
             uint256 assetPrice = storageContract.getAssetPrice(assetsMinted[i]);
             uint256 assetValue = assetAmount * assetPrice;
             totalValueMinted += assetValue;
         }
         //return collateral / totalValueMinted 
         return collateralValue  / totalValueMinted;
    }

    function createTradingPairOnUniswap(string memory tickerSymbol) external returns(address) {
        uint24 fee = 3000;
        address syntheticContract = tickersymbolToSynthContractAddress[tickerSymbol];
        address newTradingPool = factory.createPool(syntheticContract, USDCAddressEthereum, fee);
        tickerSymbolToTradingPool[tickerSymbol] = newTradingPool;
    }

}

interface ISyntheticAsset {
    function mint(address to, uint256 amount) external;
}

interface ICollateralFunds {
    function getCollateralByAddress (address _addr) external view returns (uint256);
}

interface IStorage {
    function getAssetPrice(string memory _asset) external view returns (uint256);
    
    function getAssetListOfUser(address _addr) external view returns (string[] memory);

    function getAssetAmountOfUser(address _addr, string memory tickerSymbol) external view returns (uint256);
}

interface IUniswapV3Factory {
    function createPool(address _addr, address _stableCoinAddress, uint24 fee) external returns (address);
}

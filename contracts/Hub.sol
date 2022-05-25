// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./samples/AuthorizedAddresses.sol";

/**
 * @title Hub Contract that coordinates Storage, Fund and Factory contract.
 * @dev The contract can mint new synthtic assets (erc20 token), check the collateral ratio of addresses
 * and liquidate addresses if the collateral ratio falls below 150%
 * @author The Everest team.
 */

contract Hub is AuthorizedAddresses {
    // Contract addresses
    ICollateralFunds public fundContract;
    IStorage public storageContract;
    IUniswapV3Factory public factory;

    mapping(string => address) public tickersymbolToSynthAssetContractAddress;
    mapping(string => address) public tickerSymbolToTradingPool;

    address public USDCKovan = 0xe22da380ee6B445bb8273C81944ADEB6E8450422;
    address public uniswapV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    /**
     * @notice gets the synthAsset contract Address from its tickerSymbol
     * @param _tickerSymbol tickerSymbol to identify the synthAsset
     * @return _addr address of synthAsset
     */
    function getSynthAssetContractAddress (string memory _tickerSymbol) public view returns (address) {
        return tickersymbolToSynthAssetContractAddress[_tickerSymbol];
    }

    /**
     * @notice mints synthAssets to a specific address
     * @param _receiver address to which token gets minted
     * @param _amount amount of token that gets minted
     * @param _tickerSymbol identifier of which token gets minted
     */
    function mintSynthAsset(address _receiver, uint256 _amount, string memory _tickerSymbol) public onlyAuthorizedAddresses{
        Factory(tickersymbolToSynthAssetContractAddress[_tickerSymbol]).mint(_receiver, _amount); 
    }

    /**
     * @notice sets the contract address of on sythetic asset (e.g synthTSLA)
     * @param _synthAssetAddress contract address
     */
    function setSynthAssetContractAddress(address _synthAssetAddress , string memory tickerSymbol) public onlyOwner{
        tickersymbolToSynthAssetContractAddress[tickerSymbol] = _synthAssetAddress ;
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
     * @dev price checking of colllateral too -> volatile collateral / depegging of stable collateral.
     * @param _addr address of user whom collateral ratio is to be checked.
     * @param _collateralTickerSymbol identifier of token used for collateral.
     * @return _collateral ratio
     */
    function getCollateralRatioByAddress(address _addr, string memory _collateralTickerSymbol) public view returns (uint256) {
        //Check amount funded
        uint256 amountFunded = fundContract.getCollateralByAddress(_addr);
        uint256 collateralPrice = storageContract.getAssetPrice(_collateralTickerSymbol);
        uint256 collateralValue = amountFunded * collateralPrice;

        //Check assets minted
        string[] memory assetsMinted = storageContract.getAssetListOfUser(_addr);
        // Total value of minted assets
        uint256 totalValueMinted = 0;
        //Sum up total value of minted assets
        for(uint i = 0; i < assetsMinted.length; i++) {
            uint256 assetAmount = storageContract.getAssetAmountOfUser(_addr, assetsMinted[i]);
            uint256 assetPrice = storageContract.getAssetPrice(assetsMinted[i]);
            uint256 assetValue = assetAmount * assetPrice;
            totalValueMinted += assetValue;
        }
        //return collateral / totalValueMinted 
        return collateralValue  / totalValueMinted;
    }

    function getCollateralRatioByAddress(address _user) public view returns (uint256) {
        //Check amount funded
        uint256 amountFunded = fundContract.getCollateralByAddress(_user);
        uint256 collateralPrice = storageContract.getAssetPrice(USDCKovan);
}

interface Factory {
    function mint(address _to, uint256 _amount) external;
}

interface ICollateralFunds {
    function getCollateralByAddress (address _addr) external view returns (uint256);
}

interface IStorage {
    function getAssetPrice(string memory _asset) external view returns (uint256);
    
    function getAssetListOfUser(address _addr) external view returns (string[] memory);

    function getAssetAmountOfUser(address _addr, string memory _tickerSymbol) external view returns (uint256);
}

interface IUniswapV3Factory {
    function createPool(address _addr, address _stableCoinAddress, uint24 _fee) external returns (address);
}

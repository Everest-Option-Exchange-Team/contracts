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
    CollateralFunds private fundContract;
    Storage private storageContract;

    address[] private authorizedAddresses;
    mapping(string => address) private tickersymbolToSynthContractAddress;


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
        SyntheticAsset(tickersymbolToSynthContractAddress[tickerSymbol]).mint(receiver, amount); 
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
        fundContract = CollateralFunds(_fundAddress);
    }

    /**
     * @notice sets the Storage contract address
     * @param _storageAddress address of Storage contract
     */
    function setStorageContract(address _storageAddress) public onlyOwner{
        storageContract = Storage(_storageAddress);
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

}

interface SyntheticAsset {
    function mint(address to, uint256 amount) external;
}

interface CollateralFunds {
    function getCollateralByAddress (address _addr) external view returns (uint256);
}

interface Storage {
    function getAssetPrice(string memory _asset) external view returns (uint256);
    
    function getAssetListOfUser(address _addr) external view returns (string[] memory);

    function getAssetAmountOfUser(address _addr, string memory tickerSymbol) external view returns (uint256);
}

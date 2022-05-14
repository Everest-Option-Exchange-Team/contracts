// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";



contract Hub is Ownable {
    Minter private minterContract;
    Fund private fundContract;
    Storage private storageContract;
    address[] private authorizedAddresses;
    mapping(string => address) private tickersymbolToAddress;


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

    function addAuthorizedAddress(address addr) public onlyOwner{
        authorizedAddresses.push(addr);
    }

    function updateContractProxy(string memory tickerSymbol, address addr) public onlyAuthorizedAddresses{
        tickersymbolToAddress[tickerSymbol] = addr; 
    }

    function mintToken(address receiver, uint256 amount) public onlyAuthorizedAddresses{
        minterContract.mint(receiver, amount); 
    }

    function setMinterContract(address _minterAddress) public onlyOwner{
        minterContract = Minter(_minterAddress);
    }

    function setFundContract(address _fundAddress) public onlyOwner{
        fundContract = Fund(_fundAddress);
    }

    function setStorageContract(address _storageAddress) public onlyOwner{
        storageContract = Storage(_storageAddress);
    }

    function checkCollateralRatio(address addr, string memory assetTickerSymbol, string memory collateralTickerSymbol) public returns (uint256) {
         uint256 amountFunded = fundContract.getAmountFundedByAddress(msg.sender);


         uint256 assetPrice = storageContract.getAssetPrice(assetTickerSymbol);
         uint256 collateralPrice = storageContract.getAssetPrice(collateralTickerSymbol);

         uint256 collateralValue = amountFunded * collateralPrice;



    }

}

interface Minter {
    function mint(address to, uint256 amount) external;
}

interface Fund {
    function getAmountFundedByAddress(address _addr) external view returns (uint256);
}

interface Storage {
    function getAssetPrice(string memory _asset) external view returns (uint256);
    
    function getAssetListOfUser(address _addr) external view returns (string[] memory);

    function getAssetAmountOfUser(address _addr, string memory tickerSymbol) external view returns (uint256);
}

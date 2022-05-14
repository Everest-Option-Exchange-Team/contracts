// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Hub is Ownable{
    Minter minterContract;
    Fund fundContract;
    Storage storageContract;
    address[] authorizedAddresses;
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

    function mintToken(address receiver, uint256 amount) public {
        this.minterContract.mint(receiver, amount); 
    }
    

    function setMinterContract(address _minterAddress) public onlyOwner{
        this.minterContract = new Minter(_minterAddress);
    }

    function setFundContract(address _fundAddress) public onlyOwner{
        this.fundContract = new Fund(_fundAddress);
    }

    function setStorageContract(address _storageAddress) public onlyOwner{
        this.storageContract = new Storage(_storageAddress);
    }

    function checkCollateralRatio() public returns (uint256) {
         uint256 amountFunded = fundContract.getAmountFundedByAddress(msg.sender);
         //TODO: 
    }

}

interface Minter {
    function mint(address to, uint256 amount) external;
}

interface Fund {
    function getAmountFundedByAddress(address _addr) external view returns (uint256);
}

interface Storage {
    //TODO: function to get price of specific stock
}
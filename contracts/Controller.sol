// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Hub {
    address minterAddress;

    function mintToken(address reciever, uint256 amount) external {
        Minter minter = Minter(minterAddress);
        minter.mint(reciever, amount);
    }

    function burnToken(address payer, uint256 amount) external {

    }

    function setMinterAddress(address _minterAddress) public{
        minterAddress = _minterAddress;
    }
}

interface Minter {
    function mint(address to, uint256 amount) external;
}
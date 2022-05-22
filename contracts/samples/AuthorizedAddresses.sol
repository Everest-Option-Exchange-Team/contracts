// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Contract module that allows children to implement access control mechanisms.
 */

abstract contract AuthorizedAddresses is Ownable{

    address[] public authorizedAddresses;

/*
 * @notice Modifier that checks that an account is part of the authorized addresses list.
 */
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
    /*
    * @notice Add a new account to the authorized addresses list.
    * @param _addr the address of the account to add to the list.
    */ 

    function addAuthorizedAddress(address _addr) public onlyOwner{
        authorizedAddresses.push(_addr);
    }

    function removeAuthorizedAddress(address addr) public onlyOwner {
        for(uint i = 0; i < authorizedAddresses.length; i++) {
            if(authorizedAddresses[i] == addr) {
                delete authorizedAddresses[i];
            }
        }
        
    }

}
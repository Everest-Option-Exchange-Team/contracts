// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Contract module that allows children to implement access control mechanisms.
 */

abstract contract AuthorizedAddresses is Ownable{

    address[] public authorizedAddresses;

    /**
    * @notice Event triggered when an account is added to the authorized addresses list.
    * @param _addr the address of the account to add to the list.
    */
    event AuthorizationGranted(address indexed _addr);

    /**
    * @notice Event triggered when an account is removed from the authorized addresses list.
    * @param _addr the address of the account to remove from the list.
    */
    event AuthorizationRevoked(address indexed _addr);

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
        emit AuthorizationGranted(_addr);
    }

    /*
    * @notice Remove an account from the authorized addresses list.
    * @param _addr the address of the account to remove from the list.
    */ 
    function removeAuthorizedAddress(address _addr) public onlyOwner {
        for(uint i = 0; i < authorizedAddresses.length; i++) {
            if(authorizedAddresses[i] == _addr) {
                delete authorizedAddresses[i];
                emit AuthorizationRevoked(_addr);
            }
        }  
    }
}
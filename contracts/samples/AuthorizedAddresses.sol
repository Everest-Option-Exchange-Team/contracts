// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Contract module that allows children to implement access control mechanisms.
 */

abstract contract AuthorizedAddresses is Ownable{

    address[] public authorizedAddresses;


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

    function addAuthorizedAddress(address addr) public onlyOwner{
        authorizedAddresses.push(addr);
    }

    function removeAuthorizedAddress(address addr) public onlyOwner {
        for(uint i = 0; i < authorizedAddresses.length; i++) {
            if(authorizedAddresses[i] == addr) {
                delete authorizedAddresses[i];
            }
        }
        
    }

}
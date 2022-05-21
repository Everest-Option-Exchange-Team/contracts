// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Minter is ERC20, Ownable {

    address[] public authorizedAddresses;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

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


   
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint amount) public onlyOwner {
        _burn(from, amount);
    }
}


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./samples/AuthorizedAddresses.sol";

/**
 * @title Factory contract that creates ERC20 synthetic asset contracts.
 * @author The Everest team.
 */
contract Factory is ERC20, AuthorizedAddresses {


    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

   
    function mint(address to, uint256 amount) public onlyAuthorizedAddresses {
        _mint(to, amount);
    }

    function burn(address from, uint amount) public onlyAuthorizedAddresses {
        _burn(from, amount);
    }
}


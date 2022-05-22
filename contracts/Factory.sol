// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./samples/AuthorizedAddresses.sol";

/**
 * @title Factory contract that creates ERC20 synthetic asset contracts.
 * @author The Everest team.
 */
contract Factory is ERC20, AuthorizedAddresses {

    /**
     * @notice sets name and tickerSymbol of new ERC20 token
     * @param name name of new ERC20 token
     * @param symbol tickerSymbol of new ERC20 token
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @notice mints new tokens
     * @param to address where tokens get minted to
     * @param amount amount of tokens that get minted
     */
    function mint(address to, uint256 amount) public onlyAuthorizedAddresses {
        _mint(to, amount);
    }
    /**
     * @notice burns new tokens
     * @param from address where tokens get burned from
     * @param amount amount of tokens that get burned
     */
    function burn(address from, uint amount) public onlyAuthorizedAddresses {
        _burn(from, amount);
    }
}


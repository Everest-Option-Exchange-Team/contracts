// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OptionToken is ERC20 {

    constructor(uint256 initialSupply, string memory tickerSymbol, string memory tokenName) ERC20(tickerSymbol, tokenName) {
        _mint(msg.sender, initialSupply);
    }
}
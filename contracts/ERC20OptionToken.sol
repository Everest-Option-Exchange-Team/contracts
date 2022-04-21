// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OptionToken is ERC20 {

    constructor(uint256 initialSupply, string memory tickerSymbol, string memory tokenName) ERC20(tickerSymbol, tokenName) {
        _mint(msg.sender, initialSupply);
    }

    /*
     *  @dev only whole option contracts allowed, no fractional options, might change in the future, for now to simplify
     */
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
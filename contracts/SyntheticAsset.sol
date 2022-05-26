// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./samples/AuthorizedAddresses.sol";

/**
 * @title Synthetic Asset contract that extends ERC20 standard.
 * @author The Everest team.
 */
contract SyntheticAsset is ERC20, AuthorizedAddresses {

    mapping(address => uint256) public userToSynthAssetEligibleToBurn;
    /**
     * @notice sets name and tickerSymbol of new ERC20 token
     * @param _name name of new ERC20 token
     * @param _symbol tickerSymbol of new ERC20 token
     */
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /**
     * @notice mints new tokens
     * @param _to address where tokens get minted to
     * @param _amount amount of tokens that get minted
     */
    function mint(address _to, uint256 _amount) public onlyAuthorizedAddresses {
        _mint(_to, _amount);
        userToSynthAssetEligibleToBurn[_to] = _amount;
    }
    /**
     * @notice burns new tokens
     * @param _from address where tokens get burned from
     * @param _amount amount of tokens that get burned
     */
    function burn(address _from, uint _amount) public onlyAuthorizedAddresses {
        require(_amount <= userToSynthAssetEligibleToBurn[_from]);
        _burn(_from, _amount);
    }
}


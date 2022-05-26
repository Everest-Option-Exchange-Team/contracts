// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Synthetic asset contract extending the ERC20 token specification.
 * @author The Everest team.
 */
contract SyntheticAsset is ERC20 {
    mapping(address => uint256) public userToSynthAssetEligibleToBurn;

    // Access-control parameters.
    address public owner;
    address public hubAddress;

    // Modifiers
    modifier onlyOwner() {
        require (msg.sender == owner, "Only the owner can call this method");
        _;
    }

    modifier onlyHub() {
        require(msg.sender == hubAddress, "Only the hub can call this method");
        _;
    }

    // Events
    event HubAddressUpdated(address oldAddress, address newAddress);

    /**
     * @notice Initialise a new synthetic asset contract.
     * @param _name the name of new ERC20 token.
     * @param _symbol the tickerSymbol of new ERC20 token.
     * @param _hubAddress the address of the hub.
     */
     //slither-disable-next-line naming-convention
    constructor(
        string memory _name,
        string memory _symbol,
        address _hubAddress
    ) ERC20(_name, _symbol) {
        owner = msg.sender;
        hubAddress = _hubAddress;
    }

    /**************************************** Mint / Burn ****************************************/

    /**
     * @notice Mint synthetic assets.
     * @param _userAddress the address of the user.
     * @param _amount the amount of assets that gets minted.
     */
     //slither-disable-next-line naming-convention
    function mint(address _userAddress, uint256 _amount) external onlyHub {
        _mint(_userAddress, _amount);
        userToSynthAssetEligibleToBurn[_userAddress] += _amount;
    }

    /**
     * @notice Burn synthetic assets.
     * @param _userAddress the address of the user.
     * @param _amount the amount of assets that gets burnt.
     */
     //slither-disable-next-line naming-convention
    function burn(address _userAddress, uint _amount) external onlyHub {
        require(_amount <= userToSynthAssetEligibleToBurn[_userAddress], "The user has not enough assets");

        _burn(_userAddress, _amount);
        userToSynthAssetEligibleToBurn[_userAddress] -= _amount;
    }

    /**************************************** Getters ****************************************/

    /**
     * @notice Return the amount of synthetic asset a user is elligible to burn.
     * @param _userAddress the address of the user.
     * @return _ the amount of synthetic asset elligible to be burnt.
     */
     //slither-disable-next-line naming-convention
    function getUserToSynthAssetEligibleToBurn(address _userAddress) external view returns (uint256) {
        return userToSynthAssetEligibleToBurn[_userAddress];
    }

    /**************************************** Setters ****************************************/

    /**
     * @notice Update the amount of synthetic asset a user is elligible to burn.
     * @param _userAddress the address of the user.
     * @param _amount the amount the user is elligible to burn.
     */
     //slither-disable-next-line naming-convention
    function setUserToSynthAssetEligibleToBurn(address _userAddress, uint256 _amount) external onlyHub {
        userToSynthAssetEligibleToBurn[_userAddress] = _amount;
    }

    /**
     * @notice Update the hub address.
     * @param _hubAddress the new hub address.
     */
     //slither-disable-next-line naming-convention
    function setHubAddress(address _hubAddress) external onlyOwner {
        require(_hubAddress != address(0), "The address parameter cannot be null");

        emit HubAddressUpdated(hubAddress, _hubAddress);
        hubAddress = _hubAddress;
    }
}

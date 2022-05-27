// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "hardhat/console.sol";

/**
 * @title Hub of the Everest protocol.
 * @dev The contract interacts will all the other contracts of the Everest ecosystem (CollateralFund,
 * PriceTracker and SyntheticAsset). It can:
 * - mint and burn any synthetic asset supported by the protocol,
 * - retrieve the collateral ratio of any everest user and liquidate users if their c-ratio falls
 *   below 150%.
 * @author The Everest team: https://github.com/Everest-Option-Exchange-Team.
 */
contract SimpleHubV1 {
    // Hub parameters.
    struct Position {
        string symbol;
        uint256 amount;
    }

    uint8 minimumCollateralRatio = 2; // 200%
    mapping(string => address) public symbolToSynthAddress;
    mapping(address => Position[]) public addressToPositions;

    // Everest addresses and contracts.
    address public collateralFundAddress;
    address public priceTrackerAddress;

    ICollateralFund internal _collateralFund;
    IPriceTracker internal _priceTracker;

    // Access-control parameters.
    address public owner;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this method");
        _;
    }

    // Events
    event SynthAssetMinted(string indexed symbol, uint256 amount, address indexed userAddress);
    event SynthAssetBurnt(string indexed symbol, uint256 amount, address indexed userAddress);
    
    event CollateralFundAddressUpdated(address oldAddress, address newAddress);
    event PriceTrackerAddressUpdated(address oldAddress, address newAddress);
    event SyntAssetAddressUpdated(string indexed symbol, address oldAddress, address newAddress);

    /**
     * @notice Initialise the contract.
     */
    //slither-disable-next-line naming-convention
    constructor() {
        owner = msg.sender;
    }

    /**************************************** Mint / Burn ****************************************/

    /**
     * @notice Mint synthetic assets.
     * @param _symbol the symbol of the synthetic asset.
     * @param _amount the amount of synthetic assets minted.
     * @param _userAddress the address of the user.
     * @return _ the status of the transaction (true if it succeeded and false if it didn't).
     */
    //slither-disable-next-line naming-convention
    function mintSynthAsset(string memory _symbol, uint256 _amount, address _userAddress) external onlyOwner returns (bool) {
        require(bytes(_symbol).length > 0, "The symbol parameter cannot be empty");
        require(_amount > 0, "The amount parameter has to be greater than zero");
        require(_userAddress != address(0), "The address parameter cannot be null");

        // Compute the new user total value minted by taking into account the new minted assets value.
        uint256 userTotalValueMinted = getUserTotalValueMinted(_userAddress);
        uint256 newMintedAssetsValue = _amount * _priceTracker.getAssetPrice(_symbol);
        uint256 newUserTotalValueMinted = userTotalValueMinted + newMintedAssetsValue;

        // Compute the user collateral value.
        uint256 userCollateralValue = getUserCollateralValue(_userAddress);
        
        // Check that the user has enough collateral.
        require(userCollateralValue > newUserTotalValueMinted * minimumCollateralRatio, "The user has not enough collateral");

        // Mint the synthetic asset.
        ISyntheticAsset(symbolToSynthAddress[_symbol]).mint(_userAddress, _amount);
        emit SynthAssetMinted(_symbol, _amount, _userAddress);

        // Update the user position.
        increaseUserPosition(_symbol, _amount, _userAddress);

        return true;
    }

    /**
     * @notice Burn synthetic assets.
     * @param _symbol the symbol of the synthetic asset.
     * @param _amount the amount of synthetic assets minted.
     * @param _userAddress the address of the user.
     */
    //slither-disable-next-line naming-convention
    function burnSynthAsset(string memory _symbol, uint256 _amount, address _userAddress) external onlyOwner returns (bool) {
        require(bytes(_symbol).length > 0, "The symbol parameter cannot be empty");
        require(_amount > 0, "The amount parameter has to be greater than zero");
        require(_userAddress != address(0), "The address parameter cannot be null");

        // Check that the user holds as many or more synthetic assets as he wants to burn.
        require(getUserPositionAmount(_symbol, _userAddress) >= _amount,
            "The user does not hold as many or more synthetic assets as he wants to burn");

        // Burn the synthetic asset.
        ISyntheticAsset(symbolToSynthAddress[_symbol]).burn(_userAddress, _amount);
        emit SynthAssetBurnt(_symbol, _amount, _userAddress);

        // Update the user position.
        decreaseUserPosition(_symbol, _amount, _userAddress);

        return true;
    }

    /**************************************** Manage user positions ****************************************/

    /**
     * @notice Increase the position of a user.
     * @dev If the position does not exist, the method creates the new position.
     * @param _symbol the symbol of the synthetic asset related to the position.
     * @param _amount the amount of the increase.
     * @param _userAddress the user address.
     */
    function increaseUserPosition(string memory _symbol, uint256 _amount, address _userAddress) internal onlyOwner {
        require(bytes(_symbol).length > 0, "The symbol parameter cannot be empty");
        require(_amount > 0, "The amount parameter has to be greater than zero");
        require(_userAddress != address(0), "The address parameter cannot be null");

        bool positionExists;

        // Iterate over all the positions of the user.
        // Check if the user has already opened a position for this specific synthetic asset.
        // If so, update the position.
        for (uint256 i = 0; i < addressToPositions[_userAddress].length; i++) {
            if (keccak256(bytes(addressToPositions[_userAddress][i].symbol)) == keccak256(bytes(_symbol))) {
                addressToPositions[_userAddress][i].amount += _amount;
                positionExists = true;
            }
        }

        // If the user has never opened a position for this synthetic asset, create a new position.
        if (!positionExists) {
            addressToPositions[_userAddress].push(Position(_symbol, _amount));
        }
    }

    /**
     * @notice Decrease the position of a user.
     * @dev If the position does not exist, the method is a no-operation.
     * @param _symbol the symbol of the synthetic asset related to the position.
     * @param _amount the amount of the decrease.
     * @param _userAddress the user address.
     */
    function decreaseUserPosition(string memory _symbol, uint256 _amount, address _userAddress) internal onlyOwner {
        require(bytes(_symbol).length > 0, "The symbol parameter cannot be empty");
        require(_amount > 0, "The amount parameter has to be greater than zero");
        require(_userAddress != address(0), "The address parameter cannot be null");
        
        // Iterate over all the positions of the user.
        for (uint256 i = 0; i < addressToPositions[_userAddress].length; i++) {
            if (keccak256(bytes(addressToPositions[_userAddress][i].symbol)) == keccak256(bytes(_symbol))) {
                addressToPositions[_userAddress][i].amount -= _amount;
            }
        }
    }

    /**************************************** Getters ****************************************/

    /**
     * @notice Returns the amount of a specific synthetic asset the user holds.
     * @param _symbol the symbol of the synthetic asset.
     * @param _userAddress the address of the user.
     * @return amount the amount of synthetic asset the user holds.
     */
    function getUserPositionAmount(string memory _symbol, address _userAddress) public view returns (uint256 amount) {
        require(bytes(_symbol).length > 0, "The symbol parameter cannot be empty");
        require(_userAddress != address(0), "The address parameter cannot be null");
        
        for (uint256 i = 0; i < addressToPositions[_userAddress].length; i++) {
            if (keccak256(bytes(addressToPositions[_userAddress][i].symbol)) == keccak256(bytes(_symbol))) {
                amount = addressToPositions[_userAddress][i].amount;
            }
        }
    }

    /**
     * @notice Return the value of all the assets minted by the user.
     * @param _userAddress the user address.
     * @return userTotalValueMinted the value of the assets minted by the user.
     * @dev The return value is priced in USDC.
     */
    function getUserTotalValueMinted(address _userAddress) public view returns (uint256 userTotalValueMinted) {
        require(_userAddress != address(0), "The address parameter cannot be null");
        
        // Iterate over all the positions of the user.
        for (uint256 i = 0; i < addressToPositions[_userAddress].length; i++) {
            Position memory position = addressToPositions[_userAddress][i];
            uint256 assetPrice = _priceTracker.getAssetPrice(position.symbol);
            userTotalValueMinted += position.amount * assetPrice;
        }
    }

    /**
     * @notice Return the value of the collateral provided by the user.
     * @param _userAddress the user address.
     * @return userCollateralValue the valueof the collateral provided by the user.
     * @dev The value is priced in USDC.
     */
    function getUserCollateralValue(address _userAddress) public view returns (uint256 userCollateralValue) {
        require(_userAddress != address(0), "The address parameter cannot be null");

        uint256 usdcPrice = uint256(_priceTracker.getUSDCPrice()); // TODO: check if we can convert a int256 type to a uint256 type.
        userCollateralValue = _collateralFund.getUserCollateralAmount(_userAddress) * usdcPrice;
    }

    /**************************************** Setters ****************************************/

    /**
     * @notice Update the address of the collateral fund contract.
     * @param _collateralFundAddress the new collateral fund address.
     */
    function setCollateralFundAddress(address _collateralFundAddress) external onlyOwner {
        require(_collateralFundAddress != address(0), "The address parameter cannot be null");
        emit CollateralFundAddressUpdated(collateralFundAddress, _collateralFundAddress);
        collateralFundAddress = _collateralFundAddress;
        _collateralFund = ICollateralFund(_collateralFundAddress);
    }

    /**
     * @notice Update the address of the price tracker contract.
     * @param _priceTrackerAddress the new price tracker address.
     */
    function setPriceTrackerAddress(address _priceTrackerAddress) external onlyOwner {
        require(_priceTrackerAddress != address(0), "The address parameter cannot be null");
        emit PriceTrackerAddressUpdated(priceTrackerAddress, _priceTrackerAddress);
        priceTrackerAddress = _priceTrackerAddress;
        _priceTracker = IPriceTracker(_priceTrackerAddress);
    }

    /**
     * @notice Update the address of a synthetic asset contract.
     * @param _symbol the symbol of the synthetic asset.
     * @param _synthAddress the new synthetic asset address.
     */
    function setSynthAssetAddress(string memory _symbol, address _synthAddress) external onlyOwner {
        require(bytes(_symbol).length > 0, "The symbol parameter cannot be empty");
        require(_synthAddress != address(0), "The address parameter cannot be null");
        emit SyntAssetAddressUpdated(_symbol, symbolToSynthAddress[_symbol], _synthAddress);
        symbolToSynthAddress[_symbol] = _synthAddress;
    }
}

// Interfaces

interface ICollateralFund {
    function getUserCollateralAmount(address userAddress) external view returns (uint256);
}

interface IPriceTracker {
    function getUSDCPrice() external view returns (int256);
    function getAssetPrice(string memory asset) external view returns (uint256);
}

interface ISyntheticAsset {
    function mint(address userAddress, uint256 amount) external;
    function burn(address userAddress, uint amount) external;
}

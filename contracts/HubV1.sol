// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/**
 * @title Hub of the Everest protocol.
 * @dev The contract interacts will all the other contracts of the Everest ecosystem (CollateralFund,
 * PriceTracker and SyntheticAsset). It can:
 * - mint and burn any synthetic asset supported by the protocol,
 * - retrieve the collateral ratio of any everest user and liquidate users if their c-ratio falls
 *   below 150%.
 * @author The Everest team: https://github.com/Everest-Option-Exchange-Team.
 */
contract HubV1 {
    // Everest addresses and contracts.
    address public collateralFundAddress;
    address public priceTrackerAddress;
    address public uniswapFactoryAddress;

    ICollateralFund internal _collateralFund;
    IPriceTracker internal _priceTracker;
    IUniswapV3Factory internal _uniswapFactory;

    // Hub parameters.
    struct Position {
        uint256 amount;
        uint256 value;
    }
    
    uint8 minCRatio = 150;
    mapping(string => address) public symbolToSynthAddress;
    mapping(string => address) public symbolToTradingPoolAddress;
    mapping(address => mapping(string => Position)) public addressToPositions;

    // USDC token parameters.
    address public usdcAddress;

    // Uniswap parameters.
    uint24 fees = 3000; // 3%

    // Access-control parameters.
    address public owner;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this method");
        _;
    }

    // Events
    event CreateTradingPool(string symbol, address tradingPoolAddress, address firstAssetAddress, address secondAssetAddress, uint24 fees);

    event CollateralFundAddressUpdated(address oldAddress, address newAddress);
    event PriceTrackerAddressUpdated(address oldAddress, address newAddress);
    event UniswapFactoryAddressUpdated(address oldAddress, address newAddress);

    /**
     * @notice Initialise the contract.
     * @param _usdcAddress the address of the USDC token contract.
     */
    //slither-disable-next-line naming-convention
    constructor(address _usdcAddress) {
        owner = msg.sender;
        usdcAddress = _usdcAddress;
    }

    /**************************************** Mint / Burn ****************************************/

    /**
     * @notice Mint synthetic assets.
     * @param _symbol the symbol of the synthetic asset.
     * @param _amount the amount of synthetic assets minted.
     * @param _receiverAddress the address of the receiver of the synthetic assets.
     */
    function mintSynthAsset(string memory _symbol, uint256 _amount, address _receiverAddress) external {
        // Check that the user's c-ratio is still above the minimal c-ratio after minting.
        (, uint256 totalValueMinted, uint256 collateralValue,) = getCollateralRatioByAddress(_receiverAddress);
        uint256 assetsPrice = _priceTracker.getAssetPrice(_symbol) * _amount;
        uint256 newCRatio = collateralValue / (totalValueMinted + assetsPrice);
        require(newCRatio > minCRatio, "User's c-ratio would be to low");

        // Mint the synthetic asset to the receiver's wallet.
        ISyntheticAsset(symbolToSynthAddress[_symbol]).mint(_receiverAddress, _amount);

        // Keep track of the user's position.
        addressToPositions[_receiverAddress][_symbol].amount += _amount;
        addressToPositions[_receiverAddress][_symbol].value += assetsPrice;
    }

    /**
     * @notice Burn synthetic assets.
     * @param _symbol the symbol of the synthetic asset.
     * @param _amount the amount of synthetic assets minted.
     * @param _receiverAddress the address of the receiver of the synthetic assets.
     */
    function burnSynthAsset(string memory _symbol, uint256 _amount, address _receiverAddress) external {
        // Burn the synthetic asset from the receiver's wallet.
        // TODO: the burn function has to return a bool (true if the burn was successfull or false).
        ISyntheticAsset(symbolToSynthAddress[_symbol]).burn(_receiverAddress, _amount);

        // Give back their collateral to the user.
        uint256 amountElligibleToBurn = ISyntheticAsset(symbolToSynthAddress[_symbol]).getAmountEligibleToBurn(_receiverAddress);
        if (_amount >= amountElligibleToBurn) {
            // Give back the value of _amount synthetic asssets in USDC to the user.
            ICollateralFund()
        } else {
            // Give back less than expected to the user since he has been liquidated.

        }

        if (_amount == ISyntheticAsset(symbolToSynthAddress[_symbol]).getAmountEligibleToBurn(_receiverAddress)) {
            string[] memory openSynthPositions = addressToPositions[_receiverAddress];
            string[] memory keepSynths = new string[](openSynthPositions.length - 1);
            bool isElementFound = false;
            for (uint256 i = 0; i < openSynthPositions.length; i++) {
                if (keccak256(bytes(openSynthPositions[i])) != keccak256(bytes(_symbol))) {
                    // If you don't want to leave a gap, you need to move each element manually
                    if (isElementFound) {
                        keepSynths[i - 1] = openSynthPositions[i];
                    } else {
                        keepSynths[i] = openSynthPositions[i];
                    }
                } else {
                    isElementFound = true;
                }
            }
            addressToPositions[_receiverAddress] = keepSynths;
        }
    }

    /**************************************** Trading Pairs ****************************************/

    /**
     * @notice Create a trading pair on Uniswap for any synthetic asset.
     * @param _symbol the ticker symbol of the synthetic asset.
     * @dev At the moment, the only supported AMM is Uniswap.
     */
    function createTradingPair(string memory _symbol) external onlyOwner {
        address syntAddress = symbolToSynthAddress[_symbol];
        address tradingPoolAddress = _uniswapFactory.createPool(syntAddress, usdcAddress, fees);
        symbolToTradingPoolAddress[_symbol] = tradingPoolAddress;
        emit CreateTradingPool(_symbol, tradingPoolAddress, syntAddress, usdcAddress, fees);
    }

    /**************************************** Getters ****************************************/

    /**
     * @notice Return the synthetic asset contract's address using its ticker symbol.
     * @param _symbol the ticker symbol of the synthetic asset.
     * @return _ the address of the synthetic asset contract.
     */
    function getSynthAssetContractAddress(string memory _symbol) public view returns (address) {
        require(bytes(_symbol).length > 0, "The symbol parameter cannot be empty");
        return symbolToSynthAddress[_symbol];
    }

    /**
     * @notice retrieve list of ticker symbols of open sAssets positions of a user
     * @param _user address of a user for which the ticker symbols should be retrieved
     */
    function getAssetListOfUserByAddress(address _user) public view returns (string[] memory) {
        return addressToPositions[_user];
    }

    /**************************************** Setters ****************************************/

    /**
     * @notice Update the CollateralFund contract's address.
     * @param _collateralFundAddress the new address of the CollateralFund contract.
     */
    function setCollateralFundsAddress(address _collateralFundAddress) external onlyOwner {
        emit CollateralFundAddressUpdated(collateralFundAddress, _collateralFundAddress);
        collateralFundAddress = _collateralFundAddress;
        _collateralFund = ICollateralFund(_collateralFundAddress);
    }

    /**
     * @notice Update the PriceTracker contract's address.
     * @param _priceTrackerAddress the new address of the PriceTracker contract.
     */
    function setPriceTrackerAddress(address _priceTrackerAddress) external onlyOwner {
        emit PriceTrackerAddressUpdated(priceTrackerAddress, _priceTrackerAddress);
        priceTrackerAddress = _priceTrackerAddress;
        _priceTracker = IPriceTracker(_priceTrackerAddress);
    }

    /**
     * @notice Update the synthetic asset contract's address using its ticker symbol.
     * @param _symbol the ticker symbol of the synthetic asset.
     */
    function setSynthAssetContractAddress( address _synthAddress, string memory _symbol) public onlyOwner {
        require(_synthAddress != address(0), "The synthetic asset address parameter cannot be null");
        require(bytes(_symbol).length > 0, "The symbol parameter cannot be empty");

        symbolToSynthAddress[_symbol] = _synthAddress;
    }

    












    /**
     * @notice checks the collateral ratio of an address.
     * @dev for all assets combined. No individual / isolated positions for now.
     * @dev price checking of collateral too -> volatile collateral / depegging of stable collateral.
     * @param _user address of user whom collateral ratio is to be checked.
     * @return ratio and @return totalValueMinted and @return collateralValue @return largestPosition
     */
    function getCollateralRatioByAddress(address _user)
        public
        view
        returns (
            uint256 ratio,
            uint256 totalValueMinted,
            uint256 collateralValue,
            Position memory largestPosition
        )
    {
        // Check amount funded
        collateralValue =
            _collateralFund.getUserCollateralAmount(_user) *
            _priceTracker.getAssetPrice("USDC");

        // Check assets minted
        string[] memory assetsMinted = addressToPositions[_user];
        // Total value of minted assets
        totalValueMinted = 0;
        // Find the largest position to be liquidated
        //Sum up total value of minted assets
        for (uint i = 0; i < assetsMinted.length; i++) {
            address sAssetAddress = symbolToSynthAddress[
                assetsMinted[i]
            ];
            ISyntheticAsset sAsset = ISyntheticAsset(sAssetAddress);
            // using ERC20 standard to retrieve asset amount
            uint256 assetAmount = sAsset.balanceOf(_user);
            uint256 assetPrice = _priceTracker.getAssetPrice(
                assetsMinted[i]
            );
            uint256 assetValue = assetAmount * assetPrice;
            if (assetValue > largestPosition.value) {
                largestPosition.tickerSymbol = assetsMinted[i];
                largestPosition.amount = assetAmount;
                largestPosition.value = assetValue;
            }
            totalValueMinted += assetValue;
        }
        ratio = 100 * (collateralValue / totalValueMinted);
        //return (ratio, totalValueMinted, collateralValue, largestPosition);
    }

    /*

    function liquidateUnderCollateralizedUsers() external {
        address[] memory users = _collateralFund.getFunders();
        //address[] memory liquidatedUsers = []; // how to code a growing list within a function, otherwise field of contract
        for (uint i = 0; i < users.length; i++) {
            (
                uint256 ratio,
                ,
                uint256 collateralValue,
                Position memory largestPosition
            ) = getCollateralRatioByAddress(users[i]);
            if (ratio < 150) {
                (
                    uint256 eligbleToBurn_t_2_1,
                    uint256 assetAmountToBuyOnUniswapAndBurn
                ) = reduceSynthAssetEligibleToBurn(
                        largestPosition.tickerSymbol,
                        users[i],
                        collateralValue
                    );
                liquidateUSDCOfUser(
                    eligbleToBurn_t_2_1,
                    users[i],
                    largestPosition.tickerSymbol
                );
            }
        }
    }

    // @return eligbleToBurn_t_2_1 and @return assetAmountToBuyOnUniswapAndBurn
    function reduceSynthAssetEligibleToBurn(
        string memory _tickerSymbol,
        address _user,
        uint256 _collateralValue_t_1
    ) internal returns (uint256, uint256) {
        address sAssetAddress = symbolToSynthAddress[
            _tickerSymbol
        ];
        ISyntheticAsset sAsset = ISyntheticAsset(sAssetAddress);
        // retrieve synthAsset that is eligible to burn t=1 which is equal to t=2
        uint256 eligbleToBurn_t_1 = sAsset.getAmountEligibleToBurn(
            _user
        );
        // asset price at t=2 equal to t=2.1
        uint256 assetPrice_t_2_1 = _priceTracker.getAssetPrice(
            _tickerSymbol
        );
        // compute eligibleToBurn at t=2.1 (after liquidation)
        uint256 eligbleToBurn_t_2_1 = (100 *
            (_collateralValue_t_1 - assetPrice_t_2_1 * eligbleToBurn_t_1)) /
            (assetPrice_t_2_1 * (150 - 1));
        // change eligibleToBurn within sAsset Contract
        sAsset.setAmountEligibleToBurn(_user, eligbleToBurn_t_2_1);
        // compute amount which should be bought from market and burned
        uint256 assetAmountToBuyOnUniswapAndBurn = eligbleToBurn_t_1 -
            eligbleToBurn_t_2_1;
        return (eligbleToBurn_t_2_1, assetAmountToBuyOnUniswapAndBurn);
    }

    function liquidateUSDCOfUser(
        uint256 _eligbleToBurn_t_2_1,
        address _user,
        string memory _tickerSymbol
    ) internal returns (uint256) {
        // collateral at t=1 which is equal to t=2
        uint256 collateral_t_1 = _collateralFund
            .getUserCollateralAmount(_user);
        // asset price at t=2 equal to t=2.1
        uint256 assetPrice_t_2_1 = _priceTracker.getAssetPrice(
            _tickerSymbol
        );
        // retrieve synthAsset that is eligible to burn t=1 which is equal to t=2
        address sAssetAddress = symbolToSynthAddress[
            _tickerSymbol
        ];
        ISyntheticAsset sAsset = ISyntheticAsset(sAssetAddress);
        uint256 eligbleToBurn_t_1 = sAsset.getAmountEligibleToBurn(
            _user
        );
        // compute the collateral value for t=2.1 which is equal to t=3
        uint256 collateral_t_2_1 = collateral_t_1 -
            assetPrice_t_2_1 *
            (eligbleToBurn_t_1 - _eligbleToBurn_t_2_1);
        // difference of collateral_t_2_1 and collateral_t_1 amount of USDC to take away from user
        uint256 usdcAmountToTakeAway = collateral_t_1 - collateral_t_2_1;
        // since USDC was sent to our contract, only their balance has just to be adjusted, less amount available to withdraw
        _collateralFund.setUserCollateralAmount(
            _user,
            collateral_t_2_1
        );
        // this amount of USDC can be used to buy sAsset
        return usdcAmountToTakeAway;
    }

    function swapUSDCsAsset() internal {
        // TOOD: implement swapping and burn receiving sAsset
    }
    */
}

// Interfaces

interface ICollateralFund {
    function getUserCollateralAmount(address userAddress) external view returns (uint256);
    function setUserCollateralAmount(address userAddress, uint256 amount) external;
    function getFunders() external view returns (address[] memory);
}

interface IPriceTracker {
    function getUSDCPrice() external view returns (int256);
    function getAssetPrice(string memory asset) external view returns (uint256);
}

interface ISyntheticAsset {
    function mint(address userAddress, uint256 amount) external;
    function burn(address userAddress, uint amount) external;
    function getAmountEligibleToBurn(address userAddress) external view returns (uint256);
    function setAmountEligibleToBurn(address userAddress, uint256 amount) external;
    function balanceOf(address userAddress) external view returns (uint256);
}

interface IUniswapV3Factory {
    function createPool(address synthAssetAddress, address stableCoinAddress, uint24 fee) external returns (address);
}

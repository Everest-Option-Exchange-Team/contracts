// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/**
 * @title Contract that coordinates the collateral funds, the price tracker and the synthetic asset contracts.
 * @dev The contract can mint new synthtic assets (erc20 token), check the collateral ratio of addresses
 * and liquidate addresses if the collateral ratio falls below 150%
 * @author The Everest team.
 */
contract Hub {
    // Access-control parameters.
    address public owner;

    // Contract addresses
    ICollateralFunds public collateralFundsContract;
    IStorage public storageContract;
    IUniswapV3Factory public factory;

    struct Position {
        string tickerSymbol;
        uint256 amount;
        uint256 value;
    }

    mapping(string => address) public tickersymbolToSynthAssetContractAddress;
    mapping(string => address) public tickerSymbolToTradingPool;
    mapping(address => string[]) public userAddressToOpenSynthPositions;

    address public USDCKovan = 0xe22da380ee6B445bb8273C81944ADEB6E8450422;
    address public uniswapV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // Modifiers
    modifier onlyOwner() {
        require (msg.sender == owner, "Only the owner can call this method");
        _;
    }

    /**
     * @notice gets the synthAsset contract Address from its tickerSymbol
     * @param _tickerSymbol tickerSymbol to identify the synthAsset
     * @return _addr address of synthAsset
     */
    function getSynthAssetContractAddress (string memory _tickerSymbol) public view returns (address) {
        return tickersymbolToSynthAssetContractAddress[_tickerSymbol];
    }

    /**
     * @notice mints synthAssets to a specific address
     * @param _receiver address to which token gets minted
     * @param _amount amount of token that gets minted
     * @param _tickerSymbol identifier of which token gets minted
     */
    function mintSynthAsset(address _receiver, uint256 _amount, string memory _tickerSymbol) public {
        // Check for collateralisation ratio
        (,uint256 totalValueMintedPreMinting, uint256 collateralValue,) = getCollateralRatioByAddress(_receiver);
        uint256 priceOfAssetToBeMinted = storageContract.getAssetPrice(_tickerSymbol);
        uint256 valueToBeMinted = priceOfAssetToBeMinted * _amount;
        uint256 ratioAfterMinting = collateralValue / (totalValueMintedPreMinting + valueToBeMinted);
        // otherwise not allowed to mint
        require(ratioAfterMinting > 150);
        ISyntheticAsset(tickersymbolToSynthAssetContractAddress[_tickerSymbol]).mint(_receiver, _amount);
        // if minted, add tickerSymbol to minted assets for a specific user, if it's the first time minting a specific asset x.
        string[] memory openSynthPositions = userAddressToOpenSynthPositions[_receiver];
        bool isInList = false;
        for(uint i = 0; i < openSynthPositions.length; i++){
            string memory currentSynth = openSynthPositions[i];
            if (keccak256(bytes(currentSynth)) == keccak256(bytes(_tickerSymbol))) {
                isInList = true;
            }
        }
        if (!isInList){
            userAddressToOpenSynthPositions[_receiver].push(_tickerSymbol);
        }
    }

    // TODO: implement burnSynthAsset, incl. updating userAddressToOpenSynthPositions

    /**
     * @notice sets the contract address of on sythetic asset (e.g synthTSLA)
     * @param _synthAssetAddress contract address
     */
    function setSynthAssetContractAddress(address _synthAssetAddress , string memory tickerSymbol) public onlyOwner {
        tickersymbolToSynthAssetContractAddress[tickerSymbol] = _synthAssetAddress ;
    }

    /**
     * @notice sets the Fund contract address
     * @param _fundAddress address of Fund contract
     */
    function setCollateralFundsContract(address _fundAddress) public onlyOwner {
        collateralFundsContract = ICollateralFunds(_fundAddress);
    }

    /**
     * @notice sets the Storage contract address
     * @param _storageAddress address of Storage contract
     */
    function setStorageContract(address _storageAddress) public onlyOwner {
        storageContract = IStorage(_storageAddress);
    }

    function createTradingPairOnUniswap(string memory tickerSymbol) external onlyOwner {
        uint24 fee = 3000;
        address syntheticContract = tickersymbolToSynthAssetContractAddress[tickerSymbol];
        address newTradingPool = factory.createPool(syntheticContract, USDCKovan, fee);
        tickerSymbolToTradingPool[tickerSymbol] = newTradingPool;
    }

    /**
     * @notice retrieve list of ticker symbols of open sAssets positions of a user
     * @param _user address of a user for which the ticker symbols should be retrieved  
     */
    function getAssetListOfUserByAddress(address _user) public view returns(string[] memory) {
        return userAddressToOpenSynthPositions[_user];
    }

    /**
     * @notice checks the collateral ratio of an address.
     * @dev for all assets combined. No individual / isolated positions for now.
     * @dev price checking of collateral too -> volatile collateral / depegging of stable collateral.
     * @param _user address of user whom collateral ratio is to be checked.
     * @return ratio and @return totalValueMinted and @return collateralValue @return largestPosition
     */
    function getCollateralRatioByAddress(address _user) public view returns (
        uint256 ratio,
        uint256 totalValueMinted,
        uint256 collateralValue,
        Position memory largestPosition) {
        // Check amount funded
        collateralValue = collateralFundsContract.getCollateralFundedByAddress(_user) * storageContract.getAssetPrice("USDC");

        // Check assets minted
        string[] memory assetsMinted = userAddressToOpenSynthPositions[_user];
        // Total value of minted assets
        totalValueMinted = 0;
        // Find the largest position to be liquidated
        //Sum up total value of minted assets
        for(uint i = 0; i < assetsMinted.length; i++) {
            address sAssetAddress = tickersymbolToSynthAssetContractAddress[assetsMinted[i]];
            ISyntheticAsset sAsset = ISyntheticAsset(sAssetAddress);
            // using ERC20 standard to retrieve asset amount
            uint256 assetAmount = sAsset.balanceOf(_user);
            uint256 assetPrice = storageContract.getAssetPrice(assetsMinted[i]);
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

    function liquidateUnderCollateralizedUsers() external {
        address[] memory users = collateralFundsContract.getFunders();
        //address[] memory liquidatedUsers = []; // how to code a growing list within a function, otherwise field of contract
        for(uint i = 0; i < users.length; i++) {
            (uint256 ratio,, uint256 collateralValue, Position memory largestPosition) = getCollateralRatioByAddress(users[i]);
            if (ratio < 150) {
                (uint256 eligbleToBurn_t_2_1, uint256 assetAmountToBuyOnUniswapAndBurn) = reduceSynthAssetEligibleToBurn(largestPosition.tickerSymbol, users[i], collateralValue);
                liquidateUSDCOfUser(eligbleToBurn_t_2_1, users[i], largestPosition.tickerSymbol);
            }
        }
    }

    /**
    
     * @return eligbleToBurn_t_2_1 and @return assetAmountToBuyOnUniswapAndBurn
    */
    function reduceSynthAssetEligibleToBurn(string memory _tickerSymbol, address _user, uint256 _collateralValue_t_1) internal returns(uint256, uint256) {
        address sAssetAddress = tickersymbolToSynthAssetContractAddress[_tickerSymbol];
        ISyntheticAsset sAsset = ISyntheticAsset(sAssetAddress);
        // retrieve synthAsset that is eligible to burn t=1 which is equal to t=2
        uint256 eligbleToBurn_t_1 = sAsset.getUserToSynthAssetEligibleToBurn(_user);
        // asset price at t=2 equal to t=2.1
        uint256 assetPrice_t_2_1 = storageContract.getAssetPrice(_tickerSymbol);
        // compute eligibleToBurn at t=2.1 (after liquidation)
        uint256 eligbleToBurn_t_2_1 = 100 * (_collateralValue_t_1 - assetPrice_t_2_1 * eligbleToBurn_t_1) / (assetPrice_t_2_1 * (150 - 1));
        // change eligibleToBurn within sAsset Contract
        sAsset.setUserToSynthAssetEligibleToBurn(_user, eligbleToBurn_t_2_1);
        // compute amount which should be bought from market and burned
        uint256 assetAmountToBuyOnUniswapAndBurn = eligbleToBurn_t_1 - eligbleToBurn_t_2_1;
        return (eligbleToBurn_t_2_1, assetAmountToBuyOnUniswapAndBurn);
    }

    function liquidateUSDCOfUser(uint256 _eligbleToBurn_t_2_1, address _user, string memory _tickerSymbol) internal returns(uint256) {
        // TODO: implement formula 2), use num(eligbleToBurn, t=2.1) from reduceSynthAssetEligibleToBurn and num(eligibleToBurn, t=2) from userToSynthAssetEligibleToBurn
        // collateral at t=1 which is equal to t=2
        uint256 collateral_t_1 = collateralFundsContract.getCollateralFundedByAddress(_user);
        // asset price at t=2 equal to t=2.1
        uint256 assetPrice_t_2_1 = storageContract.getAssetPrice(_tickerSymbol);
        // retrieve synthAsset that is eligible to burn t=1 which is equal to t=2
        address sAssetAddress = tickersymbolToSynthAssetContractAddress[_tickerSymbol];
        ISyntheticAsset sAsset = ISyntheticAsset(sAssetAddress);
        uint256 eligbleToBurn_t_1 = sAsset.getUserToSynthAssetEligibleToBurn(_user);
        // compute the collateral value for t=2.1 which is equal to t=3
        uint256 collateral_t_2_1 = collateral_t_1 - assetPrice_t_2_1 * (eligbleToBurn_t_1 - _eligbleToBurn_t_2_1);
        // difference of collateral_t_2_1 and collateral_t_1 amount of USDC to take away from user
        uint256 usdcAmountToTakeAway = collateral_t_1 - collateral_t_2_1;
        // since USDC was sent to our contract, only their balance has just to be adjusted, less amount available to withdraw
        collateralFundsContract.setCollateralFundedByAddress(_user, collateral_t_2_1);
        // this amount of USDC can be used to buy sAsset
        return usdcAmountToTakeAway;
    }

    function swapUSDCsAsset() internal {
        // TOOD: implement swapping and burn receiving sAsset
    }

}

interface ISyntheticAsset {
    function balanceOf(address account) external view returns (uint256); 

    function getUserToSynthAssetEligibleToBurn(address _user) external view returns (uint256);

    function setUserToSynthAssetEligibleToBurn(address _user, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;
}

interface ICollateralFunds {
    function getFunders() external view returns (address[] memory); 

    function getCollateralFundedByAddress(address _addr) external view returns (uint256);

    function setCollateralFundedByAddress(address _user, uint256 _amount) external;
}

interface IStorage {
    function getAssetPrice(string memory _asset) external view returns (uint256);
    
    function getAssetListOfUser(address _addr) external view returns (string[] memory);

    function getAssetAmountOfUser(address _addr, string memory _tickerSymbol) external view returns (uint256);
}

interface IUniswapV3Factory {
    function createPool(address _addr, address _stableCoinAddress, uint24 _fee) external returns (address);
}

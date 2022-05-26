// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./samples/AuthorizedAddresses.sol";

/**
 * @title Hub Contract that coordinates Storage, Fund and Factory contract.
 * @dev The contract can mint new synthtic assets (erc20 token), check the collateral ratio of addresses
 * and liquidate addresses if the collateral ratio falls below 150%
 * @author The Everest team.
 */

contract Hub is AuthorizedAddresses {
    // Contract addresses
    ICollateralFunds public collateralFundsContract;
    IStorage public storageContract;
    IUniswapV3Factory public factory;

    mapping(string => address) public tickersymbolToSynthAssetContractAddress;
    mapping(string => address) public tickerSymbolToTradingPool;
    mapping(address => string[]) public userAddressToOpenSynthPositions;

    address public USDCKovan = 0xe22da380ee6B445bb8273C81944ADEB6E8450422;
    address public uniswapV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

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
    function mintSynthAsset(address _receiver, uint256 _amount, string memory _tickerSymbol) public onlyAuthorizedAddresses{
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

    /**
     * @notice sets the contract address of on sythetic asset (e.g synthTSLA)
     * @param _synthAssetAddress contract address
     */
    function setSynthAssetContractAddress(address _synthAssetAddress , string memory tickerSymbol) public onlyOwner{
        tickersymbolToSynthAssetContractAddress[tickerSymbol] = _synthAssetAddress ;
    }

    /**
     * @notice sets the Fund contract address
     * @param _fundAddress address of Fund contract
     */
    function setCollateralFundsContract(address _fundAddress) public onlyOwner{
        collateralFundsContract = ICollateralFunds(_fundAddress);
    }

    /**
     * @notice sets the Storage contract address
     * @param _storageAddress address of Storage contract
     */
    function setStorageContract(address _storageAddress) public onlyOwner{
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
    function getAssetListOfUserByAddress(address _user) public returns(string[] memory) {
        return userAddressToOpenSynthPositions[_user];
    }

    /**
     * @notice checks the collateral ratio of an address.
     * @dev for all assets combined. No individual / isolated positions for now.
     * @dev price checking of collateral too -> volatile collateral / depegging of stable collateral.
     * @param _user address of user whom collateral ratio is to be checked.
     * @return _collateral ratio
     */
    function getCollateralRatioByAddress(address _user) public view returns (uint256, uint256, uint256, string memory, uint256, uint256) {
        //Check amount funded
        uint256 amountFunded = collateralFundsContract.getCollateralByAddress(_user);
        uint256 collateralPrice = storageContract.getAssetPrice('USDC');
        uint256 collateralValue = amountFunded * collateralPrice;

        //Check assets minted
        string[] memory assetsMinted = userAddressToOpenSynthPositions[_user];
        // Total value of minted assets
        uint256 totalValueMinted = 0;
        // Find the largest position to be liquidated
        string memory largestPositionTickerSymbol = "";
        uint256 largestPositionAmount = 0;
        uint256 largestPositionValue = 0;  // <- here end
        //Sum up total value of minted assets
        for(uint i = 0; i < assetsMinted.length; i++) {
            address sAssetAddress = tickersymbolToSynthAssetContractAddress[assetsMinted[i]];
            ISyntheticAsset sAsset = ISyntheticAsset(sAssetAddress);
            // using ERC20 standard to retrieve asset amount
            uint256 assetAmount = sAsset.balanceOf(_user);
            uint256 assetPrice = storageContract.getAssetPrice(assetsMinted[i]);
            uint256 assetValue = assetAmount * assetPrice;
            if (assetValue > largestPositionValue) {
                largestPositionTickerSymbol = assetsMinted[i];
                largestPositionAmount = assetAmount;
                largestPositionValue = assetValue;
            }
            totalValueMinted += assetValue;
        }
        uint256 ratio = 100 * (collateralValue / totalValueMinted);
        return (ratio, totalValueMinted, collateralValue, largestPositionTickerSymbol, largestPositionAmount, largestPositionValue);
    }

    function liquidateUnderCollateralizedUsers() external onlyAuthorizedAddresses {
        address[] memory users = collateralFundsContract.getFunders();
        address[] memory liquidatedUsers = []; // how to code a growing list within a function, otherwise field of contract
        for(uint i = 0; i < users.length; i++) {
            (uint256 ratio,
            uint256 totalValueMinted,
            uint256 collateralValue,
            string memory largestPositionTickerSymbol,
            uint256 largestPositionAmount,
            uint256 largestPositionValue) = getCollateralRatioByAddress(users[i]);
            if (ratio < 150) {
                // compute amount and asset to be liquidated
                uint256 maximalAllowedValueMintedInUSD = collateralValue / 150;
                uint256 assetAmountAllowedToHave = maximalAllowedValueMintedInUSD / storageContract.getAssetPrice(largestPositionTickerSymbol);
                uint256 assetAmountToSellToRevertToOnePointFive = largestPositionAmount - assetAmountAllowedToHave;
                if (assetAmountToSellToRevertToOnePointFive < 0) {
                    // next bigger asset gets liquidated in the next step
                    //liquidateUser(largestPositionAmount);
                    reduceSynthAssetEligibleToBurn(assetAmountToSellToRevertToOnePointFive, largestPositionTickerSymbol, users[i]);
                    liquidatedUsers.push(users[i]);
                } else{
                    // this functions need amount
                    //liquidateUser(assetAmountToSellToRevertToOnePointFive);
                    liquidatedUsers.push(users[i]);
                }
            }
        }
    }

    function reduceSynthAssetEligibleToBurn(uint256 assetAmount, string memory _tickerSymbol, address _user) internal {
        address sAssetAddress = tickersymbolToSynthAssetContractAddress[_tickerSymbol];
        ISyntheticAsset sAsset = ISyntheticAsset(sAssetAddress);
        uint256 synthAssetEligibleToBurnBeforeLiquidation = sAsset.userToSynthAssetEligibleToBurn[_user];
        // implement formula 1)
    }

}

interface ISyntheticAsset {
    function balanceOf(address account) public view virtual override returns (uint256); 

    function mint(address _to, uint256 _amount) external;
}

interface ICollateralFunds {
    function getFunders() external view returns (address[] memory); 

    function getCollateralByAddress(address _addr) external view returns (uint256);
}

interface IStorage {
    function getAssetPrice(string memory _asset) external view returns (uint256);
    
    function getAssetListOfUser(address _addr) external view returns (string[] memory);

    function getAssetAmountOfUser(address _addr, string memory _tickerSymbol) external view returns (uint256);
}

interface IUniswapV3Factory {
    function createPool(address _addr, address _stableCoinAddress, uint24 _fee) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/**
 * @title A simple contract to which you can deposit or withdraw collateral funds, and invoke a synthAssetMint.
 * @author The Everest team.
 */
contract CollateralFunds {
    mapping(address => uint256) public collateralFundedByAddress;
    uint256 public totalCollateral ;
    address[] public funders;
    address hubAddress;


    /**
     * @notice constructor
     * @param _hubAddress address of the Hub contract.
     */
    constructor(address _hubAddress) {
        hubAddress = _hubAddress;
    }

    /**
     * @notice Event triggered when user deposits funds to the contract.
     * @param addr the address of the user.
     * @param amount the amount deposited by the user during the transaction.
     * @param balance the user balance (funds deposited by the user and not yet withdrawn).
     */
    event Deposit(address indexed addr, uint256 amount, uint256 balance);

    /**
     * @notice Event triggered when user withdraws funds from the contract.
     * @param addr the address of the user.
     * @param amount the amount withdrawn by the user during the transaction.
     * @param balance the user balance (funds deposited by the user and not yet withdrawn).
     */
    event Withdraw(address indexed addr, uint256 amount, uint256 balance);

    /**
     * @notice Send money to the fund.
     */
    function fundCollateral() external payable {
        collateralFundedByAddress[msg.sender] += msg.value;
        totalCollateral  += msg.value;
        funders.push(msg.sender);
        emit Deposit(msg.sender, msg.value, collateralFundedByAddress[msg.sender]);
    }

    /**
     * @notice Withdraw money from the fund.
     * @param _amount the amount to withdraw from the fund.
     */
    function withdraw(uint256 _amount) external payable {
        require(_amount <= collateralFundedByAddress[msg.sender], "You can't withdraw more than what you deposited");
        collateralFundedByAddress[msg.sender] -= _amount;
        totalCollateral  -= _amount;
        emit Withdraw(msg.sender, _amount, collateralFundedByAddress[msg.sender]);
        payable(msg.sender).transfer(_amount);
    }

    /**
     * @notice Get the list of users who have funded the smart contract.
     * @return _ the list of funders
     */
    function getFunders() external view returns (address[] memory) {
        return funders;
    }

    /**
     * @notice Get the amount deposited by a user.
     * @param _addr address
     * @return _ amount deposited by a user
     */
    //slither-disable-next-line naming-convention
    function getCollateralFundedByAddress(address _addr) external view returns (uint256) {
        return collateralFundedByAddress[_addr];
    }

    /*
     * @notice Get the total amount funded to this smart contract.
     * @return _ the amount of the total funds
     */
    function getTotalCollateral () external view returns (uint256) {
        return totalCollateral ;
    }

    /**
     * @notice Check if user deposited required amount. Sends information to the hub.
     * @param _amountTokens  amountToken user wants to Mint
     * @dev Firstly: 1 Token = Avax, Later: 1 Token = c ratio * real asset price
     */
    function mintERC20Tokens(uint256 _amountTokens ) external {
        require(collateralFundedByAddress[msg.sender] >= _amountTokens  * 1 ether, "Not enough capital deposited");
        Hub hub = Hub(hubAddress);
        hub.mintSynthAsset(msg.sender, _amountTokens );
    }

}

interface Hub {
    function mintSynthAsset(address reciever, uint256 amount) external;
}

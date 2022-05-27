// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/**
 * @title Contract that allows users to managed their collateral funds.
 * @dev For the moment, the only collateral accepted is the USDC.
 * @author The Everest team: https://github.com/Everest-Option-Exchange-Team.
 */
contract CollateralFunds {
    mapping(address => uint256) public collateralFundedByAddress;
    uint256 public totalCollateral;
    address[] public funders;

    ERC20Token public usdcKovan; 

    // Access-control parameters.
    address hubAddress;

    // Modifiers
    modifier onlyHub() {
        require(msg.sender == hubAddress, "Only the hub can call this method");
        _;
    }

    // Events
    event Deposit(address indexed _addr, uint256 _amount, uint256 _balance);
    event Withdraw(address indexed _addr, uint256 _amount, uint256 _balance);

    /**
     * @notice Initialise the contract.
     * @param _hubAddress the address of the hub.
     */
    constructor(address _hubAddress) {
        hubAddress = _hubAddress;
    }

    /**
     * @notice Send collateral to the fund.
     */
    function fund() external payable {
        // TODO: change to USDC instead of Ether
        collateralFundedByAddress[msg.sender] += msg.value;
        totalCollateral += msg.value;
        funders.push(msg.sender);
        emit Deposit(
            msg.sender,
            msg.value,
            collateralFundedByAddress[msg.sender]
        );
    }

    /**
     * @notice Withdraw collateral from the fund.
     * @param _amount the amount to withdraw from the fund.
     */
    function withdraw(uint256 _amount) external payable {
        // TODO: change to USDC instead of Ether
        require(
            _amount <= collateralFundedByAddress[msg.sender],
            "You can't withdraw more than what you deposited"
        );
        collateralFundedByAddress[msg.sender] -= _amount;
        totalCollateral -= _amount;
        emit Withdraw(
            msg.sender,
            _amount,
            collateralFundedByAddress[msg.sender]
        );
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
    function getCollateralFundedByAddress(address _addr)
        external
        view
        returns (uint256)
    {
        return collateralFundedByAddress[_addr];
    }

    function setCollateralFundedByAddress(address _user, uint256 _amount)
        public
        onlyHub
    {
        collateralFundedByAddress[_user] = _amount;
    }

    /*
     * @notice Get the total amount funded to this smart contract.
     * @return _ the amount of the total funds
     */
    function getTotalCollateral() external view returns (uint256) {
        return totalCollateral;
    }

    /**
     * @notice Check if user deposited required amount. Sends information to the hub.
     * @param _amountTokens  amountToken user wants to Mint
     * @dev Firstly: 1 Token = Avax, Later: 1 Token = c ratio * real asset price
     */
    function mintERC20Tokens(uint256 _amountTokens) external {
        require(
            collateralFundedByAddress[msg.sender] >= _amountTokens * 1 ether,
            "Not enough capital deposited"
        );
        Hub hub = Hub(hubAddress);
        hub.mintSynthAsset(msg.sender, _amountTokens);
    }
}

// Interfaces

interface IERC20 {
    function transfer(address receiverAddress, uint amount) external returns (bool);
    function transferFrom(address senderAddress, address receiverAddress, uint amount) external returns (bool);
    function balanceOf(address userAddress) external view returns (uint);
}

interface Hub {
    function mintSynthAsset(address receiver, uint256 amount) external;
}

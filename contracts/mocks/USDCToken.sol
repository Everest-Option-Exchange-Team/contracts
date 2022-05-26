// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract USDCToken {
    // Token parameters.
    string public constant name = "USDCStableCoin";
    string public constant symbol = "USDC";
    uint8 public constant decimals = 18;

    // Users parameters.
    mapping(address => uint256) addressToBalance;
    mapping(address => mapping(address => uint256)) addressToAllowance;
    uint256 totalSupply_;

    // Access-control parameters.
    address public owner;

    // Events
    event Approval(address indexed tokenOwnerAddress, address indexed spenderAddress, uint256 amount);
    event Transfer(address indexed senderAddress, address indexed receiverAddress, uint256 amount);

    constructor(uint256 _total) {
        owner = msg.sender;
        addressToBalance[msg.sender] = _total;
        totalSupply_ = _total;
    }

    function balanceOf(address _userAddress) public view returns (uint) {
        return addressToBalance[_userAddress];
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _receiverAddress, uint _amount) public returns (bool) {
        require(_amount >= 0);
        require(_amount <= addressToBalance[msg.sender]);

        addressToBalance[msg.sender] -= _amount;
        addressToBalance[_receiverAddress] += _amount;
        emit Transfer(msg.sender, _receiverAddress, _amount);

        return true;
    }

    function approve(address _delegateAddress, uint _amount) public returns (bool) {
        require(_delegateAddress != address(0));
        require(_amount >= 0);

        addressToAllowance[msg.sender][_delegateAddress] = _amount;
        emit Approval(msg.sender, _delegateAddress, _amount);

        return true;
    }

    function allowance(address _ownerAddress, address _delegateAddress) public view returns (uint) {
        return addressToAllowance[_ownerAddress][_delegateAddress];
    }

    function transferFrom(address _senderAddress, address _receiverAddress, uint _amount) public returns (bool) {
        require(_amount <= addressToBalance[_senderAddress]);
        require(_amount <= addressToAllowance[_senderAddress][msg.sender]);

        addressToBalance[_senderAddress] -= _amount;
        addressToBalance[_receiverAddress] += _amount;
        addressToAllowance[_senderAddress][msg.sender] -= _amount;
        emit Transfer(_senderAddress, _receiverAddress, _amount);
        
        return true;
    }
}

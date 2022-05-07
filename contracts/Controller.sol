// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Controller {
    address minterAddress;

    function mintToken(address reciever, uint256 amount) external {
        ERC20MinterPauser minter = ERC20MinterPauser(minterAddress);
        minter.mint(reciever, amount);
    }

    function burnToken(address payer, uint256 amount) external {

    }

    function setMinterAddress(address _minterAddress) public{
        minterAddress = _minterAddress;
    }
}

interface ERC20MinterPauser {
    function mint(address to, uint256 amount) external;
    function pause() external;
    function unpause() external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint amount) external;

}
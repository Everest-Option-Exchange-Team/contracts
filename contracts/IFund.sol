// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IFund {
    function swap() external payable;
}

contract Interaction {
    address fundContractAddress;

    function setFundContractAddress(address _fund) public payable {
        fundContractAddress = _fund;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @title A simple contract to which you can send money and then withdraw it.
 * @author The Everest team.
 */
contract Fund {
    mapping(address => uint256) public addressToAmountFunded;
    uint256 public totalFunds;
    address[] public funders;

    /**
     * @notice Send money to the fund.
     */
    function fund() public payable {
        addressToAmountFunded[msg.sender] += msg.value;
        totalFunds += msg.value;
        funders.push(msg.sender);
    }

    /**
     * @notice Withdraw money from the fund.
     * It will withdraw all the money the user sent to the fund to its wallet.
     * TODO: Enable the user to withdraw only a fraction of its funding.
     */
    function withdraw() public payable {
        payable(msg.sender).transfer(addressToAmountFunded[msg.sender]);
    }

    /**
     * @notice Get the list of users who have funded the smart contract.
     * @return _ the list of funders
     */
    function getFunders() public view returns (address[] memory) {
        return funders;
    }

    /**
     * @notice Get the total amount funded to this smart contract.
     * @return _ the amount of the total funds 
     */
    function getTotalFunds() public view returns (uint256) {
        return totalFunds;
    }

}

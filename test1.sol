// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AverageBank {

    address public owner;
    mapping(address => uint256) public balances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function emergencyWithdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
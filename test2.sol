// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableVault {

    struct User {
        uint256 balance;
        uint256 reward;
        address referrer;
        uint256 lastDeposit;
    }

    mapping(address => User) public users;

    address public owner;
    uint256 public totalDeposits;
    uint256 public rewardRate = 10; // fake APR
    bool public paused;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    // Deposit ETH
    function deposit(address referrer) public payable notPaused {
        User storage user = users[msg.sender];

        if (user.referrer == address(0) && referrer != msg.sender) {
            user.referrer = referrer;
        }

        _updateReward(msg.sender);

        user.balance += msg.value;
        totalDeposits += msg.value;
        user.lastDeposit = block.timestamp;
    }

    // 🔴 Reentrancy vulnerability
    function withdraw(uint256 amount) public {
        User storage user = users[msg.sender];
        require(user.balance >= amount, "Insufficient");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);

        user.balance -= amount;
        totalDeposits -= amount;
    }

    // Claim rewards
    function claimReward() public {
        _updateReward(msg.sender);

        uint256 reward = users[msg.sender].reward;
        users[msg.sender].reward = 0;

        payable(msg.sender).transfer(reward);
    }

    // 🔴 Anyone can change reward rate
    function setRewardRate(uint256 rate) public {
        rewardRate = rate;
    }

    // 🔴 Dangerous admin withdrawal
    function emergencyWithdrawAll() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    // 🔴 Timestamp dependency
    function _updateReward(address userAddr) internal {
        User storage user = users[userAddr];

        uint256 timeDiff = block.timestamp - user.lastDeposit;
        uint256 reward = (user.balance * rewardRate * timeDiff) / 1e18;

        user.reward += reward;
        user.lastDeposit = block.timestamp;
    }

    // Pause contract
    function togglePause() public onlyOwner {
        paused = !paused;
    }

    receive() external payable {}
}

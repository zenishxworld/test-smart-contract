// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceStaking is ReentrancyGuard, Ownable {

    struct User {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
    }

    mapping(address => User) public users;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public voted;

    uint256 public totalStaked;
    uint256 public accRewardPerShare;
    uint256 public rewardRate = 1e18;
    uint256 public proposalCount;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Voted(address indexed user, uint256 proposalId, bool support);

    function stake() external payable nonReentrant {
        User storage user = users[msg.sender];

        _updateRewards();

        if (user.amount > 0) {
            uint256 pending = (user.amount * accRewardPerShare) - user.rewardDebt;
            payable(msg.sender).transfer(pending);
        }

        user.amount += msg.value;
        totalStaked += msg.value;

        user.rewardDebt = user.amount * accRewardPerShare;

        emit Staked(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external nonReentrant {
        User storage user = users[msg.sender];
        require(user.amount >= amount, "Insufficient");

        _updateRewards();

        uint256 pending = (user.amount * accRewardPerShare) - user.rewardDebt;

        user.amount -= amount;
        totalStaked -= amount;

        user.rewardDebt = user.amount * accRewardPerShare;

        payable(msg.sender).transfer(amount + pending);

        emit Withdrawn(msg.sender, amount);
    }

    function createProposal(string memory desc, uint256 duration) public {
        proposals[proposalCount] = Proposal(
            desc,
            0,
            0,
            block.timestamp + duration,
            false
        );
        proposalCount++;
    }

    function vote(uint256 id, bool support) public {
        require(!voted[msg.sender][id], "Already voted");

        Proposal storage prop = proposals[id];
        require(block.timestamp < prop.endTime, "Ended");

        uint256 votingPower = users[msg.sender].amount;

        if (support) {
            prop.votesFor += votingPower;
        } else {
            prop.votesAgainst += votingPower;
        }

        voted[msg.sender][id] = true;

        emit Voted(msg.sender, id, support);
    }

    function execute(uint256 id) public onlyOwner {
        Proposal storage prop = proposals[id];
        require(!prop.executed, "Executed");

        prop.executed = true;
    }

    function _updateRewards() internal {
        if (totalStaked == 0) return;
        accRewardPerShare += rewardRate / totalStaked;
    }
}

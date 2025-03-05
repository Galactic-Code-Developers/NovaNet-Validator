// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovaNetValidator.sol";
import "./AIValidatorSelection.sol";
import "./AIRewardDistribution.sol";
import "./AISlashingMonitor.sol";
import "./AISlashingAppeal.sol";
import "./AIVotingModel.sol";

contract DelegatorContract is Ownable {
    struct Delegation {
        address delegator;
        address validator;
        uint256 amount;
        uint256 lastRewardClaim;
    }

    NovaNetValidator public validatorContract;
    AIValidatorSelection public aiValidatorSelection;
    AIRewardDistribution public aiRewardDistribution;
    AISlashingMonitor public slashingMonitor;
    AISlashingAppeal public slashingAppeal;
    AIVotingModel public votingModel;

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public totalStakedByDelegator;

    event StakeDelegated(address indexed delegator, address indexed validator, uint256 amount);
    event StakeWithdrawn(address indexed delegator, uint256 amount);
    event RewardsClaimed(address indexed delegator, uint256 amount);
    event DelegatorSlashed(address indexed delegator, uint256 penalty);

    constructor(
        address _validatorContract,
        address _aiValidatorSelection,
        address _aiRewardDistribution,
        address _slashingMonitor,
        address _slashingAppeal,
        address _votingModel
    ) {
        validatorContract = NovaNetValidator(_validatorContract);
        aiValidatorSelection = AIValidatorSelection(_aiValidatorSelection);
        aiRewardDistribution = AIRewardDistribution(_aiRewardDistribution);
        slashingMonitor = AISlashingMonitor(_slashingMonitor);
        slashingAppeal = AISlashingAppeal(_slashingAppeal);
        votingModel = AIVotingModel(_votingModel);
    }

    /// @notice Delegate stake to an AI-selected validator
    function delegateStake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens.");
        require(delegations[msg.sender].validator == address(0), "Already staked.");

        address bestValidator = aiValidatorSelection.selectBestValidator();
        require(bestValidator != address(0), "No suitable validators found.");

        delegations[msg.sender] = Delegation(msg.sender, bestValidator, amount, block.timestamp);
        totalStakedByDelegator[msg.sender] += amount;
        validatorContract.stake(msg.sender, bestValidator, amount);

        emit StakeDelegated(msg.sender, bestValidator, amount);
    }

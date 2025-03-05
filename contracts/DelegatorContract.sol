// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NovaNetValidator.sol";

contract DelegatorContract {
    address public owner;
    NovaNetValidator public novaNetValidator;

    struct Delegation {
        uint256 amount;
        address validator;
    }

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public totalDelegatedToValidator;
    
    event DelegationAdded(address indexed delegator, address indexed validator, uint256 amount);
    event RewardsClaimed(address indexed delegator, uint256 amount);

    constructor(address _validatorContract) {
        owner = msg.sender;
        novaNetValidator = NovaNetValidator(_validatorContract);
    }

    function delegateStake(address validator, uint256 amount) external {
        require(amount > 0, "Cannot delegate zero");
        require(novaNetValidator.getValidatorStake(validator) > 0, "Validator does not exist");
        
        delegations[msg.sender] = Delegation(amount, validator);
        totalDelegatedToValidator[validator] += amount;

        emit DelegationAdded(msg.sender, validator, amount);
    }

    function claimRewards() external {
        Delegation memory delegation = delegations[msg.sender];
        require(delegation.amount > 0, "No delegation found");

        uint256 reward = delegation.amount / 10; // Example reward logic (10% of stake)
        payable(msg.sender).transfer(reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    function getValidators() external view returns (address[] memory) {
        // Needs implementation to track active validators
    }
}

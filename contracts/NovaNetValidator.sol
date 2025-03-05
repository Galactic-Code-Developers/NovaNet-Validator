// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DelegatorContract.sol";

contract NovaNetValidator {
    address public owner;
    uint256 public totalStaked;
    mapping(address => uint256) public validatorStakes;
    mapping(address => bool) public isValidator;
    
    DelegatorContract public delegatorContract;

    event ValidatorRegistered(address indexed validator, uint256 stake);
    event StakeIncreased(address indexed validator, uint256 amount);
    event RewardsDistributed(address indexed validator, uint256 amount);
    
    constructor(address _delegatorContract) {
        owner = msg.sender;
        delegatorContract = DelegatorContract(_delegatorContract);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyValidator() {
        require(isValidator[msg.sender], "Not a validator");
        _;
    }

    function registerValidator(address validator, uint256 stakeAmount) external onlyOwner {
        require(!isValidator[validator], "Already a validator");
        require(stakeAmount > 0, "Stake must be greater than zero");
        
        isValidator[validator] = true;
        validatorStakes[validator] = stakeAmount;
        totalStaked += stakeAmount;

        emit ValidatorRegistered(validator, stakeAmount);
    }

    function increaseStake(uint256 amount) external onlyValidator {
        require(amount > 0, "Invalid stake amount");
        
        validatorStakes[msg.sender] += amount;
        totalStaked += amount;
        
        emit StakeIncreased(msg.sender, amount);
    }

    function distributeRewards() external onlyOwner {
        address[] memory validators = delegatorContract.getValidators();
        
        for (uint256 i = 0; i < validators.length; i++) {
            uint256 reward = validatorStakes[validators[i]] / 10; // Example reward logic (10% of stake)
            payable(validators[i]).transfer(reward);
            emit RewardsDistributed(validators[i], reward);
        }
    }

    function getValidatorStake(address validator) external view returns (uint256) {
        return validatorStakes[validator];
    }
}

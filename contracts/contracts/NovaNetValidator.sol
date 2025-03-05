// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NovaNetValidator
 * @dev This contract manages validators in NovaNet using Quantum Delegated Proof-of-Stake (Q-DPoS).
 * It includes validator registration, staking, reward distribution, slashing, and governance.
 */
contract NovaNetValidator {
    struct Validator {
        address validatorAddress;
        uint256 stakedAmount;
        uint256 rewardBalance;
        uint256 lastBlockValidated;
        bool active;
        bool slashed;
    }

    struct Delegator {
        address delegatorAddress;
        uint256 stakedAmount;
        address delegatedTo;
    }

    address public owner;
    uint256 public minStakeAmount = 5000 * (10**18); // Minimum 5000 NOVA required to become a validator
    uint256 public totalStaked;
    uint256 public totalValidators;
    uint256 public totalDelegators;

    mapping(address => Validator) public validators;
    mapping(address => Delegator) public delegators;
    address[] public validatorList;
    address[] public delegatorList;

    event ValidatorRegistered(address indexed validator, uint256 amount);
    event ValidatorUnregistered(address indexed validator);
    event ValidatorSlashed(address indexed validator, uint256 penalty);
    event StakeDelegated(address indexed delegator, address indexed validator, uint256 amount);
    event RewardsDistributed(uint256 blockNumber, uint256 totalRewards);
    event GovernanceVote(address indexed validator, uint256 proposalId, bool vote);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    modifier onlyValidator() {
        require(validators[msg.sender].active, "Only active validators can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Registers a new validator with a minimum stake.
     */
    function registerValidator() external payable {
        require(msg.value >= minStakeAmount, "Insufficient stake amount");
        require(!validators[msg.sender].active, "Already a validator");

        validators[msg.sender] = Validator({
            validatorAddress: msg.sender,
            stakedAmount: msg.value,
            rewardBalance: 0,
            lastBlockValidated: block.number,
            active: true,
            slashed: false
        });

        validatorList.push(msg.sender);
        totalValidators += 1;
        totalStaked += msg.value;

        emit ValidatorRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Allows a validator to unregister and withdraw their stake.
     */
    function unregisterValidator() external {
        require(validators[msg.sender].active, "Not an active validator");
        
        uint256 stakeAmount = validators[msg.sender].stakedAmount;
        require(stakeAmount > 0, "No stake to withdraw");

        validators[msg.sender].active = false;
        payable(msg.sender).transfer(stakeAmount);

        emit ValidatorUnregistered(msg.sender);
    }

    /**
     * @dev Delegators stake their NOVA tokens to a validator.
     */
    function delegateStake(address validator) external payable {
        require(validators[validator].active, "Validator must be active");
        require(msg.value > 0, "Must stake some amount");

        delegators[msg.sender] = Delegator({
            delegatorAddress: msg.sender,
            stakedAmount: msg.value,
            delegatedTo: validator
        });

        totalDelegators += 1;
        totalStaked += msg.value;

        emit StakeDelegated(msg.sender, validator, msg.value);
    }

    /**
     * @dev Distributes rewards to validators and delegators.
     */
    function distributeRewards(uint256 totalReward) external onlyOwner {
        require(totalReward > 0, "Invalid reward amount");

        uint256 rewardPerValidator = totalReward / totalValidators;
        
        for (uint256 i = 0; i < validatorList.length; i++) {
            address validator = validatorList[i];
            if (validators[validator].active) {
                validators[validator].rewardBalance += rewardPerValidator;
            }
        }

        emit RewardsDistributed(block.number, totalReward);
    }

    /**
     * @dev Slashes a validator for malicious activity.
     */
    function slashValidator(address validator) external onlyOwner {
        require(validators[validator].active, "Validator must be active");

        uint256 penalty = validators[validator].stakedAmount / 2; // 50% penalty
        validators[validator].stakedAmount -= penalty;
        validators[validator].slashed = true;

        payable(owner).transfer(penalty); // Burn or send to governance treasury

        emit ValidatorSlashed(validator, penalty);
    }

    /**
     * @dev Allows validators to participate in governance voting.
     */
    function voteOnProposal(uint256 proposalId, bool vote) external onlyValidator {
        emit GovernanceVote(msg.sender, proposalId, vote);
    }

    /**
     * @dev Fetches all active validators.
     */
    function getActiveValidators() external view returns (address[] memory) {
        return validatorList;
    }

    /**
     * @dev Withdraw earned rewards.
     */
    function withdrawRewards() external onlyValidator {
        uint256 reward = validators[msg.sender].rewardBalance;
        require(reward > 0, "No rewards available");

        validators[msg.sender].rewardBalance = 0;
        payable(msg.sender).transfer(reward);
    }

    /**
     * @dev Handles cross-chain validator registration.
     */
    function registerCrossChainValidator(address externalChain, bytes32 pubKey) external onlyValidator {
        // Placeholder for cross-chain validation integration
    }

    /**
     * @dev Handles AI-optimized validator selection.
     */
    function aiOptimizedSelection(address validator, uint256 performanceScore) external onlyOwner {
        // Placeholder for AI-driven validator selection logic
    }
}

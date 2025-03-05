// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AIValidatorReputation.sol";
import "./NovaNetValidator.sol";

contract AIValidatorRewards {
    AIValidatorReputation public reputationContract;
    NovaNetValidator public validatorContract;

    event RewardsDistributed(address indexed validator, uint256 rewardAmount);

    constructor(address _reputationContract, address _validatorContract) {
        reputationContract = AIValidatorReputation(_reputationContract);
        validatorContract = NovaNetValidator(_validatorContract);
    }

    function distributeRewards(address _validator) external {
        uint256 repScore = reputationContract.getReputationScore(_validator);
        require(repScore > 50, "Validator reputation too low");

        uint256 baseReward = 10 ether;
        uint256 bonusReward = (repScore * baseReward) / 100;

        uint256 totalReward = baseReward + bonusReward;
        validatorContract.allocateReward(_validator, totalReward);

        emit RewardsDistributed(_validator, totalReward);
    }
}

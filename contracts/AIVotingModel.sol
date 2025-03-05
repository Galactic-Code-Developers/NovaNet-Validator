// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovaNetValidator.sol";

contract AIVotingModel is Ownable {
    NovaNetValidator public validatorContract;

    mapping(address => uint256) public reputationScores;

    event ReputationUpdated(address indexed validator, uint256 newReputation);

    constructor(address _validatorContract) {
        validatorContract = NovaNetValidator(_validatorContract);
    }

    function adjustVotingPower(address voter, uint256 stake) external view returns (uint256) {
        uint256 reputation = getReputationScore(voter);
        return (stake * reputation) / 100;
    }

    function updateReputation(address validator, bool positive) external onlyOwner {
        uint256 currentScore = reputationScores[validator];

        if (positive) {
            reputationScores[validator] = currentScore + 5;
        } else {
            reputationScores[validator] = currentScore > 5 ? currentScore - 5 : 0;
        }

        emit ReputationUpdated(validator, reputationScores[validator]);
    }

    function getReputationScore(address validator) public view returns (uint256) {
        return reputationScores[validator] > 0 ? reputationScores[validator] : 50; // Default reputation is 50
    }
}

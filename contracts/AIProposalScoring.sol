// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIProposalScoring is Ownable {
    struct ProposalScore {
        uint256 proposalId;
        address proposer;
        uint256 feasibilityScore; // 0-100
        uint256 networkImpactScore; // 0-100
        uint256 securityRiskScore; // 0-100
        uint256 finalScore; // Weighted final score
        bool approved; // AI-based approval or rejection
        string reason;
        uint256 timestamp;
    }

    mapping(uint256 => ProposalScore) public proposalScores;
    uint256 public proposalCount;

    event ProposalEvaluated(
        uint256 indexed proposalId,
        address indexed proposer,
        uint256 feasibilityScore,
        uint256 networkImpactScore,
        uint256 securityRiskScore,
        uint256 finalScore,
        bool approved,
        string reason,
        uint256 timestamp
    );

    // AI-Driven Proposal Evaluation
    function evaluateProposal(
        uint256 _proposalId,
        address _proposer,
        uint256 _feasibilityScore,
        uint256 _networkImpactScore,
        uint256 _securityRiskScore
    ) external onlyOwner {
        require(_feasibilityScore <= 100 && _networkImpactScore <= 100 && _securityRiskScore <= 100, "Scores must be between 0-100");

        uint256 finalScore = (_feasibilityScore * 40 / 100) + (_networkImpactScore * 40 / 100) - (_securityRiskScore * 20 / 100);

        bool approved = finalScore >= 50; // AI threshold for approval
        string memory reason = approved ? "Proposal approved by AI evaluation" : "Proposal rejected due to low AI score";

        proposalScores[_proposalId] = ProposalScore({
            proposalId: _proposalId,
            proposer: _proposer,
            feasibilityScore: _feasibilityScore,
            networkImpactScore: _networkImpactScore,
            securityRiskScore: _securityRiskScore,
            finalScore: finalScore,
            approved: approved,
            reason: reason,
            timestamp: block.timestamp
        });

        emit ProposalEvaluated(_proposalId, _proposer, _feasibilityScore, _networkImpactScore, _securityRiskScore, finalScore, approved, reason, block.timestamp);
    }

    // Get Proposal Score
    function getProposalScore(uint256 _proposalId) external view returns (
        uint256 feasibilityScore,
        uint256 networkImpactScore,
        uint256 securityRiskScore,
        uint256 finalScore,
        bool approved,
        string memory reason
    ) {
        ProposalScore storage score = proposalScores[_proposalId];
        return (
            score.feasibilityScore,
            score.networkImpactScore,
            score.securityRiskScore,
            score.finalScore,
            score.approved,
            score.reason
        );
    }

    // Check if Proposal is Approved
    function isProposalApproved(uint256 _proposalId) external view returns (bool) {
        return proposalScores[_proposalId].approved;
    }
}

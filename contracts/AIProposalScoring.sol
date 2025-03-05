// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIProposalScoring is Ownable {
    struct ProposalAnalysis {
        uint256 proposalId;
        uint256 aiScore;
        bool approved;
        string reason;
    }

    mapping(uint256 => ProposalAnalysis) public proposalEvaluations;

    event ProposalEvaluated(uint256 indexed proposalId, uint256 aiScore, bool approved, string reason);

    function evaluateProposal(
        uint256 _proposalId,
        string memory _description,
        uint256 _fundAmount,
        address proposer
    ) external onlyOwner returns (bool) {
        uint256 aiScore = calculateAIScore(_description, _fundAmount, proposer);
        bool approved = aiScore >= 50; // AI rejects proposals below 50%

        string memory reason = approved ? "Approved" : "Rejected due to low AI score";

        proposalEvaluations[_proposalId] = ProposalAnalysis({
            proposalId: _proposalId,
            aiScore: aiScore,
            approved: approved,
            reason: reason
        });

        emit ProposalEvaluated(_proposalId, aiScore, approved, reason);
        return approved;
    }

    function calculateAIScore(
        string memory _description,
        uint256 _fundAmount,
        address proposer
    ) internal pure returns (uint256) {
        uint256 score = 100;

        if (_fundAmount > 50000 ether) {
            score -= 40; // High funding requests get penalized
        }

        if (bytes(_description).length < 50) {
            score -= 20; // Penalize low-detail proposals
        }

        return score;
    }

    function getProposalEvaluation(uint256 _proposalId) external view returns (ProposalAnalysis memory) {
        return proposalEvaluations[_proposalId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AIProposalScoring.sol";

contract AIExecutionFilter {
    AIProposalScoring public proposalScoring;

    event ProposalBlocked(uint256 indexed id);

    constructor(address _proposalScoring) {
        proposalScoring = AIProposalScoring(_proposalScoring);
    }

    function validateProposalExecution(uint256 _proposalId) external view returns (bool) {
        uint256 score = proposalScoring.proposals(_proposalId).aiScore;
        return score >= 75; // Ensures only high-quality proposals execute
    }
}

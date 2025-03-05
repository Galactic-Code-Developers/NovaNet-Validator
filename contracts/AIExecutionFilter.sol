// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AIProposalScoring.sol";

contract AIExecutionFilter is Ownable {
    AIProposalScoring public proposalScoring;

    mapping(uint256 => bool) public executionStatus;

    event ExecutionApproved(uint256 indexed proposalId);
    event ExecutionBlocked(uint256 indexed proposalId, string reason);

    constructor(address _proposalScoring) {
        proposalScoring = AIProposalScoring(_proposalScoring);
    }

    function validateExecution(uint256 _proposalId) external onlyOwner returns (bool) {
        AIProposalScoring.ProposalAnalysis memory analysis = proposalScoring.getProposalEvaluation(_proposalId);

        if (!analysis.approved || analysis.aiScore < 60) {
            emit ExecutionBlocked(_proposalId, "Proposal failed AI quality checks");
            return false;
        }

        executionStatus[_proposalId] = true;
        emit ExecutionApproved(_proposalId);
        return true;
    }
}

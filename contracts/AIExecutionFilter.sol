// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AIProposalScoring.sol";
import "./AIExecutionMonitor.sol";

contract AIExecutionFilter is Ownable {
    AIProposalScoring public aiProposalScoring;
    AIExecutionMonitor public aiExecutionMonitor;

    struct ExecutionRequest {
        uint256 proposalId;
        address proposer;
        uint256 aiScore;
        uint256 securityRisk;
        uint256 networkImpact;
        bool approved;
    }

    mapping(uint256 => ExecutionRequest) public executionQueue;
    uint256 public executionCount;
    uint256 public constant MIN_AI_SCORE = 75; // Minimum AI score required for execution
    uint256 public constant MAX_SECURITY_RISK = 30; // Maximum security risk allowed

    event ExecutionRequested(uint256 indexed proposalId, address indexed proposer, uint256 aiScore, uint256 securityRisk, uint256 networkImpact);
    event ExecutionApproved(uint256 indexed proposalId);
    event ExecutionRejected(uint256 indexed proposalId, string reason);

    constructor(address _aiProposalScoring, address _aiExecutionMonitor) {
        aiProposalScoring = AIProposalScoring(_aiProposalScoring);
        aiExecutionMonitor = AIExecutionMonitor(_aiExecutionMonitor);
    }

    function requestExecution(uint256 _proposalId, address _proposer) external onlyOwner {
        require(_proposalId > 0, "Invalid proposal ID");

        uint256 aiScore = aiProposalScoring.getProposalScore(_proposalId);
        uint256 securityRisk = aiProposalScoring.getSecurityRisk(_proposalId);
        uint256 networkImpact = aiProposalScoring.getNetworkImpact(_proposalId);

        executionCount++;
        executionQueue[executionCount] = ExecutionRequest({
            proposalId: _proposalId,
            proposer: _proposer,
            aiScore: aiScore,
            securityRisk: securityRisk,
            networkImpact: networkImpact,
            approved: false
        });

        emit ExecutionRequested(_proposalId, _proposer, aiScore, securityRisk, networkImpact);
    }

    function evaluateExecution(uint256 _executionId) external onlyOwner {
        ExecutionRequest storage request = executionQueue[_executionId];
        require(request.proposalId > 0, "Invalid execution request");

        if (request.aiScore >= MIN_AI_SCORE && request.securityRisk <= MAX_SECURITY_RISK) {
            request.approved = true;
            aiExecutionMonitor.logExecutionApproval(request.proposalId, request.aiScore, request.securityRisk);
            emit ExecutionApproved(request.proposalId);
        } else {
            request.approved = false;
            aiExecutionMonitor.logExecutionRejection(request.proposalId, request.aiScore, request.securityRisk);
            emit ExecutionRejected(request.proposalId, "AI score too low or security risk too high");
        }
    }

    function getExecutionStatus(uint256 _executionId) external view returns (bool approved, uint256 aiScore, uint256 securityRisk, uint256 networkImpact) {
        ExecutionRequest storage request = executionQueue[_executionId];
        return (request.approved, request.aiScore, request.securityRisk, request.networkImpact);
    }
}

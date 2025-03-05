// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIExecutionMonitor is Ownable {
    struct ExecutionLog {
        uint256 proposalId;
        address proposer;
        uint256 aiScore;
        uint256 securityRisk;
        uint256 networkImpact;
        bool approved;
        string reason;
        uint256 timestamp;
    }

    ExecutionLog[] public executionLogs;

    event ExecutionLogged(
        uint256 indexed proposalId,
        address indexed proposer,
        uint256 aiScore,
        uint256 securityRisk,
        uint256 networkImpact,
        bool approved,
        string reason,
        uint256 timestamp
    );

    function logExecutionApproval(uint256 _proposalId, uint256 _aiScore, uint256 _securityRisk) external onlyOwner {
        executionLogs.push(
            ExecutionLog({
                proposalId: _proposalId,
                proposer: msg.sender,
                aiScore: _aiScore,
                securityRisk: _securityRisk,
                networkImpact: 0, // Placeholder for future impact tracking
                approved: true,
                reason: "Proposal met AI execution criteria",
                timestamp: block.timestamp
            })
        );

        emit ExecutionLogged(_proposalId, msg.sender, _aiScore, _securityRisk, 0, true, "Proposal met AI execution criteria", block.timestamp);
    }

    function logExecutionRejection(uint256 _proposalId, uint256 _aiScore, uint256 _securityRisk) external onlyOwner {
        executionLogs.push(
            ExecutionLog({
                proposalId: _proposalId,
                proposer: msg.sender,
                aiScore: _aiScore,
                securityRisk: _securityRisk,
                networkImpact: 0,
                approved: false,
                reason: "Proposal rejected due to AI evaluation",
                timestamp: block.timestamp
            })
        );

        emit ExecutionLogged(_proposalId, msg.sender, _aiScore, _securityRisk, 0, false, "Proposal rejected due to AI evaluation", block.timestamp);
    }

    function getExecutionLog(uint256 index) external view returns (
        uint256 proposalId,
        address proposer,
        uint256 aiScore,
        uint256 securityRisk,
        uint256 networkImpact,
        bool approved,
        string memory reason,
        uint256 timestamp
    ) {
        require(index < executionLogs.length, "Invalid index");
        ExecutionLog storage log = executionLogs[index];
        return (
            log.proposalId,
            log.proposer,
            log.aiScore,
            log.securityRisk,
            log.networkImpact,
            log.approved,
            log.reason,
            log.timestamp
        );
    }

    function getTotalLogs() external view returns (uint256) {
        return executionLogs.length;
    }
}

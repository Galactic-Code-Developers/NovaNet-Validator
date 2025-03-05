// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AIGovernanceAudit {
    struct GovernanceRecord {
        uint256 timestamp;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 aiScore;
    }

    mapping(uint256 => GovernanceRecord) public auditLogs;
    uint256 public recordCount;

    event GovernanceActionLogged(uint256 indexed recordId, address proposer, uint256 aiScore);

    function logGovernanceAction(
        uint256 _proposalId,
        address _proposer,
        string memory _description,
        uint256 _votesFor,
        uint256 _votesAgainst,
        uint256 _aiScore
    ) external {
        recordCount++;
        auditLogs[recordCount] = GovernanceRecord(
            block.timestamp,
            _proposer,
            _description,
            _votesFor,
            _votesAgainst,
            _aiScore
        );

        emit GovernanceActionLogged(recordCount, _proposer, _aiScore);
    }
}

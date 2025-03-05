// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AIValidatorAudit.sol";
import "./AIValidatorReputation.sol";

contract AIValidatorAdjustment {
    AIValidatorAudit public auditContract;
    AIValidatorReputation public reputationContract;

    event ReputationUpdated(address indexed validator, uint256 newScore);

    constructor(address _auditContract, address _reputationContract) {
        auditContract = AIValidatorAudit(_auditContract);
        reputationContract = AIValidatorReputation(_reputationContract);
    }

    function autoAdjustReputation(address _validator) external {
        AIValidatorAudit.AuditRecord[] memory logs = auditContract.getAuditLogs(_validator);
        uint256 totalScore;
        uint256 logCount = logs.length;

        for (uint256 i = 0; i < logCount; i++) {
            totalScore += logs[i].uptime + logs[i].blockValidationCount - (logs[i].slashingEvents * 5);
        }

        uint256 newScore = totalScore / logCount;
        reputationContract.updateReputation(_validator, newScore, logs[logCount - 1].blockValidationCount, 0);

        emit ReputationUpdated(_validator, newScore);
    }
}

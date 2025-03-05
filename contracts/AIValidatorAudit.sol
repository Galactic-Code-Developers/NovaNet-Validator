// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AIValidatorReputation.sol";
import "./NovaNetValidator.sol";

contract AIValidatorAudit {
    struct AuditRecord {
        uint256 timestamp;
        address validator;
        uint256 uptime;
        uint256 stake;
        uint256 blockValidationCount;
        uint256 slashingEvents;
        bool flagged;
    }

    mapping(address => AuditRecord[]) public auditLogs;
    AIValidatorReputation public reputationContract;
    NovaNetValidator public validatorContract;

    event ValidatorAuditLogged(address indexed validator, uint256 timestamp, bool flagged);

    constructor(address _reputationContract, address _validatorContract) {
        reputationContract = AIValidatorReputation(_reputationContract);
        validatorContract = NovaNetValidator(_validatorContract);
    }

    function auditValidator(address _validator) external {
        uint256 uptime = validatorContract.getValidatorUptime(_validator);
        uint256 stake = validatorContract.getValidatorStake(_validator);
        uint256 blockCount = validatorContract.getValidatorBlockCount(_validator);
        uint256 slashingEvents = validatorContract.getSlashingCount(_validator);
        
        bool flagged = slashingEvents > 3 || uptime < 70; // Auto-flag if uptime drops below 70% or multiple slashes
        
        auditLogs[_validator].push(AuditRecord(
            block.timestamp,
            _validator,
            uptime,
            stake,
            blockCount,
            slashingEvents,
            flagged
        ));

        if (flagged) {
            reputationContract.updateReputation(_validator, uptime, blockCount, 0);
        }

        emit ValidatorAuditLogged(_validator, block.timestamp, flagged);
    }

    function getAuditLogs(address _validator) external view returns (AuditRecord[] memory) {
        return auditLogs[_validator];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AIValidatorAudit.sol";
import "./NovaNetValidator.sol";

contract AISlashingReview {
    struct Appeal {
        uint256 id;
        address validator;
        string reason;
        uint256 appealTime;
        bool resolved;
        bool successful;
    }

    uint256 public appealCount;
    mapping(uint256 => Appeal) public appeals;
    AIValidatorAudit public auditContract;
    NovaNetValidator public validatorContract;

    event AppealSubmitted(uint256 indexed id, address indexed validator, string reason);
    event AppealResolved(uint256 indexed id, bool successful);

    constructor(address _auditContract, address _validatorContract) {
        auditContract = AIValidatorAudit(_auditContract);
        validatorContract = NovaNetValidator(_validatorContract);
    }

    function submitAppeal(string memory _reason) external {
        require(validatorContract.isValidator(msg.sender), "Only validators can appeal");

        appealCount++;
        appeals[appealCount] = Appeal(appealCount, msg.sender, _reason, block.timestamp, false, false);

        emit AppealSubmitted(appealCount, msg.sender, _reason);
    }

    function resolveAppeal(uint256 _appealId, bool _approve) external {
        Appeal storage appeal = appeals[_appealId];
        require(!appeal.resolved, "Appeal already resolved");

        appeal.resolved = true;
        appeal.successful = _approve;

        if (_approve) {
            validatorContract.restoreValidator(appeal.validator);
        }

        emit AppealResolved(_appealId, _approve);
    }
}

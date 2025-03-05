// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovaNetValidator.sol";
import "./DelegatorContract.sol";
import "./Treasury.sol";
import "./AIAuditLogger.sol";

contract Governance is Ownable {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        ProposalType proposalType;
        uint256 fundAmount;
        address payable recipient;
        uint256 aiScore; // AI-driven governance scoring
        mapping(address => bool) voted;
    }

    enum ProposalType { GENERAL, SLASH_VALIDATOR, TREASURY_ALLOCATION, PARAMETER_UPDATE, NETWORK_UPGRADE }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => string) public aiAuditLogs; // AI governance audit logs

    NovaNetValidator public validatorContract;
    DelegatorContract public delegatorContract;
    Treasury public treasury;
    AIAuditLogger public auditLogger; // AI-driven governance audit logger

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description, uint256 aiScore);
    event VoteCasted(uint256 indexed id, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed id);
    event AIAuditLogCreated(uint256 indexed proposalId, string auditLog);
    event TreasuryFunded(address indexed recipient, uint256 amount, uint256 aiScore);

    constructor(
        address _validatorContract,
        address _delegatorContract,
        address _treasury,
        address _auditLogger
    ) {
        validatorContract = NovaNetValidator(_validatorContract);
        delegatorContract = DelegatorContract(_delegatorContract);
        treasury = Treasury(_treasury);
        auditLogger = AIAuditLogger(_auditLogger);
    }

    modifier onlyValidatorOrDelegator() {
        require(
            validatorContract.getValidatorStake(msg.sender) > 0 ||
            delegatorContract.hasDelegated(msg.sender),
            "Not a validator or active delegator"
        );
        _;
    }

    function submitProposal(
        string memory _description,
        uint256 _duration,
        ProposalType _type,
        uint256 _fundAmount,
        address payable _recipient
    ) external onlyValidatorOrDelegator {
        proposalCount++;
        uint256 aiScore = calculateAIScore(_description, _type, _fundAmount);

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + _duration;
        newProposal.executed = false;
        newProposal.proposalType = _type;
        newProposal.fundAmount = _fundAmount;
        newProposal.recipient = _recipient;
        newProposal.aiScore = aiScore;

        // Log AI audit trail
        string memory auditEntry = string(
            abi.encodePacked(
                "Proposal ID: ", uintToString(proposalCount),
                " | AI Score: ", uintToString(aiScore),
                " | Type: ", proposalTypeToString(_type),
                " | Description: ", _description
            )
        );
        auditLogger.logGovernanceAction(proposalCount, auditEntry);

        emit AIAuditLogCreated(proposalCount, auditEntry);
        emit ProposalCreated(proposalCount, msg.sender, _description, aiScore);
    }

    function vote(uint256 _proposalId, bool _support) external onlyValidatorOrDelegator {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.voted[msg.sender], "Already voted");

        uint256 votingPower = validatorContract.getValidatorStake(msg.sender);
        if (votingPower == 0) {
            votingPower = delegatorContract.getDelegatedStake(msg.sender);
        }

        require(votingPower > 0, "No voting power");
        proposal.voted[msg.sender] = true;

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit VoteCasted(_proposalId, msg.sender, _support, votingPower);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Already executed");
        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved");

        proposal.executed = true;

        if (proposal.proposalType == ProposalType.SLASH_VALIDATOR) {
            validatorContract.slashValidator(proposal.recipient);
        } else if (proposal.proposalType == ProposalType.TREASURY_ALLOCATION) {
            uint256 aiAdjustedFunds = calculateAITreasuryFunding(proposal.fundAmount, proposal.aiScore);
            treasury.allocateFunds(proposal.recipient, aiAdjustedFunds);
            emit TreasuryFunded(proposal.recipient, aiAdjustedFunds, proposal.aiScore);
        } else if (proposal.proposalType == ProposalType.PARAMETER_UPDATE) {
            validatorContract.updateNetworkParameter(proposal.fundAmount);
        } else if (proposal.proposalType == ProposalType.NETWORK_UPGRADE) {
            // Execute network upgrade logic
        }

        // Log execution in AI audit system
        string memory executionLog = string(
            abi.encodePacked(
                "Executed Proposal ID: ", uintToString(_proposalId),
                " | AI Score: ", uintToString(proposal.aiScore),
                " | Type: ", proposalTypeToString(proposal.proposalType)
            )
        );
        auditLogger.logGovernanceAction(_proposalId, executionLog);

        emit ProposalExecuted(_proposalId);
    }

    function calculateAIScore(
        string memory _description,
        ProposalType _type,
        uint256 _fundAmount
    ) internal pure returns (uint256) {
        uint256 score = 100;
        if (_type == ProposalType.TREASURY_ALLOCATION && _fundAmount > 10000 ether) {
            score -= 30;
        }
        if (_type == ProposalType.SLASH_VALIDATOR) {
            score += 20;
        }
        return score;
    }

    function calculateAITreasuryFunding(uint256 requestedAmount, uint256 aiScore) internal pure returns (uint256) {
        return (requestedAmount * aiScore) / 100;
    }

    function uintToString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) return "0";
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    function proposalTypeToString(ProposalType _type) internal pure returns (string memory) {
        if (_type == ProposalType.GENERAL) return "GENERAL";
        if (_type == ProposalType.SLASH_VALIDATOR) return "SLASH_VALIDATOR";
        if (_type == ProposalType.TREASURY_ALLOCATION) return "TREASURY_ALLOCATION";
        if (_type == ProposalType.PARAMETER_UPDATE) return "PARAMETER_UPDATE";
        if (_type == ProposalType.NETWORK_UPGRADE) return "NETWORK_UPGRADE";
        return "UNKNOWN";
    }
}

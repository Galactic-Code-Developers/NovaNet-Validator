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
        auditLogger.logAudit(proposalCount, "PROPOSAL_SUBMITTED", 0, msg.sender);

        emit ProposalCreated(proposalCount, msg.sender, _description, aiScore);
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

        auditLogger.logAudit(_proposalId, "PROPOSAL_EXECUTED", proposal.fundAmount, msg.sender);

        emit ProposalExecuted(_proposalId);
    }

    function getAIAuditLog(uint256 proposalId) external view returns (AIAuditLogger.AuditLog memory) {
        return auditLogger.getAuditLogByProposalId(proposalId);
    }

    function calculateAITreasuryFunding(uint256 requestedAmount, uint256 aiScore) internal pure returns (uint256) {
        return (requestedAmount * aiScore) / 100;
    }
}

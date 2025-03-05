// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovaNetValidator.sol";
import "./DelegatorContract.sol";
import "./Treasury.sol";

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

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description, uint256 aiScore);
    event VoteCasted(uint256 indexed id, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed id);
    event AIAuditLogCreated(uint256 indexed proposalId, string auditLog);
    event DelegationOptimized(address indexed delegator, address indexed validator, uint256 stakeAmount);

    constructor(address _validatorContract, address _delegatorContract, address _treasury) {
        validatorContract = NovaNetValidator(_validatorContract);
        delegatorContract = DelegatorContract(_delegatorContract);
        treasury = Treasury(_treasury);
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
        aiAuditLogs[proposalCount] = string(
            abi.encodePacked(
                "Proposal ID: ", uintToString(proposalCount),
                " | AI Score: ", uintToString(aiScore),
                " | Type: ", proposalTypeToString(_type),
                " | Description: ", _description
            )
        );
        emit AIAuditLogCreated(proposalCount, aiAuditLogs[proposalCount]);

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
            treasury.allocateFunds(proposal.recipient, proposal.fundAmount);
        } else if (proposal.proposalType == ProposalType.PARAMETER_UPDATE) {
            validatorContract.updateNetworkParameter(proposal.fundAmount);
        } else if (proposal.proposalType == ProposalType.NETWORK_UPGRADE) {
            // Execute network upgrade logic
        }

        emit ProposalExecuted(_proposalId);
    }

    function optimizeDelegation(address delegator) external onlyOwner {
        address bestValidator = validatorContract.getBestValidator();
        uint256 stakeAmount = delegatorContract.getDelegatedStake(delegator);

        require(stakeAmount > 0, "No stake to delegate");

        delegatorContract.redelegateStake(delegator, bestValidator);
        emit DelegationOptimized(delegator, bestValidator, stakeAmount);
    }

    function getProposal(uint256 _proposalId) external view returns (
        address proposer, string memory description, uint256 votesFor, uint256 votesAgainst, bool executed, uint256 aiScore
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.proposer, proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.executed, proposal.aiScore);
    }

    function getAIAuditLog(uint256 _proposalId) external view returns (string memory) {
        return aiAuditLogs[_proposalId];
    }

    function calculateAIScore(
        string memory _description,
        ProposalType _type,
        uint256 _fundAmount
    ) internal pure returns (uint256) {
        uint256 score = 100;
        if (_type == ProposalType.TREASURY_ALLOCATION && _fundAmount > 10000 ether) {
            score -= 30; // Reduce score for large fund requests
        }
        if (_type == ProposalType.SLASH_VALIDATOR) {
            score += 20; // Increase score for slashing proposals
        }
        return score;
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

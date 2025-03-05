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
        uint256 aiScore;
        mapping(address => bool) voted;
    }

    enum ProposalType { GENERAL, SLASH_VALIDATOR, TREASURY_ALLOCATION, PARAMETER_UPDATE, NETWORK_UPGRADE }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    NovaNetValidator public validatorContract;
    DelegatorContract public delegatorContract;
    Treasury public treasury;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description, uint256 aiScore);
    event VoteCasted(uint256 indexed id, address indexed voter, bool support, uint256 weightedVote);
    event ProposalExecuted(uint256 indexed id, bool success);

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
        uint256 proposalImpactScore = AIProposalScoring.evaluateProposal(msg.sender, _description, _type, _fundAmount);
        require(proposalImpactScore > 50, "Proposal impact score too low");

        proposalCount++;
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
        newProposal.aiScore = proposalImpactScore;

        emit ProposalCreated(proposalCount, msg.sender, _description, proposalImpactScore);
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

        uint256 aiAdjustedVotePower = AIVotingModel.calculateVotingPower(msg.sender, votingPower);
        require(aiAdjustedVotePower > 0, "Voting power too low");

        proposal.voted[msg.sender] = true;

        if (_support) {
            proposal.votesFor += aiAdjustedVotePower;
        } else {
            proposal.votesAgainst += aiAdjustedVotePower;
        }

        emit VoteCasted(_proposalId, msg.sender, _support, aiAdjustedVotePower);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Already executed");
        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved");

        bool aiApproved = AIExecutionFilter.verifyProposalExecution(_proposalId, proposal.votesFor, proposal.votesAgainst);
        require(aiApproved, "Proposal rejected by AI security filter");

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

        emit ProposalExecuted(_proposalId, true);
    }

    function getProposal(uint256 _proposalId) external view returns (
        address proposer, string memory description, uint256 votesFor, uint256 votesAgainst, bool executed, uint256 aiScore
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.proposer, proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.executed, proposal.aiScore);
    }
}

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
        mapping(address => bool) voted;
    }

    enum ProposalType { GENERAL, SLASH_VALIDATOR, TREASURY_ALLOCATION, PARAMETER_UPDATE, NETWORK_UPGRADE }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    NovaNetValidator public validatorContract;
    DelegatorContract public delegatorContract;
    Treasury public treasury;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description);
    event VoteCasted(uint256 indexed id, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed id);

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

        emit ProposalCreated(proposalCount, msg.sender, _description);
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

        emit VoteCasted(_proposalId, msg.sender, _support);
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

    function getProposal(uint256 _proposalId) external view returns (
        address proposer, string memory description, uint256 votesFor, uint256 votesAgainst, bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.proposer, proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.executed);
    }
}

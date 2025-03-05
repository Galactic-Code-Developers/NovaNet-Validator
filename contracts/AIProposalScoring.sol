// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIProposalScoring is Ownable {
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 timestamp;
        uint256 aiScore;
        bool approved;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public proposerReputation;

    event ProposalEvaluated(uint256 indexed id, uint256 aiScore, bool approved);

    function submitProposal(string memory _description) external {
        uint256 aiScore = _evaluateProposal(msg.sender, _description);
        bool approved = aiScore >= 60; // Requires at least 60% score

        proposalCount++;
        proposals[proposalCount] = Proposal(proposalCount, _description, msg.sender, block.timestamp, aiScore, approved);

        emit ProposalEvaluated(proposalCount, aiScore, approved);
    }

    function _evaluateProposal(address _proposer, string memory _description) internal view returns (uint256) {
        uint256 repScore = proposerReputation[_proposer];
        uint256 textQuality = _analyzeText(_description);
        return (repScore + textQuality) / 2;
    }

    function _analyzeText(string memory _text) internal pure returns (uint256) {
        return bytes(_text).length % 100; // Placeholder for AI text analysis
    }

    function updateReputation(address _proposer, uint256 _score) external onlyOwner {
        proposerReputation[_proposer] = _score;
    }
}

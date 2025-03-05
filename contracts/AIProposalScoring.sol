// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AIProposalScoring {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 aiScore;
        bool approved;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    event ProposalScored(uint256 indexed id, uint256 aiScore, bool approved);

    function scoreProposal(string memory _description) public returns (uint256) {
        proposalCount++;
        uint256 aiScore = calculateAIScore(_description);

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            aiScore: aiScore,
            approved: aiScore > 60 // AI approves proposals with a score > 60
        });

        emit ProposalScored(proposalCount, aiScore, proposals[proposalCount].approved);
        return aiScore;
    }

    function calculateAIScore(string memory _description) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_description))) % 100;
    }
}

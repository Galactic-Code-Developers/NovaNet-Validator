// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AIEconomicPredictor.sol";

contract AISmartGovAnalyzer is Ownable {
    AIEconomicPredictor public economicPredictor;

    event ProposalAnalyzed(uint256 proposalId, uint256 impactScore, bool recommendedForFunding);

    constructor(address _economicPredictor) {
        economicPredictor = AIEconomicPredictor(_economicPredictor);
    }

    function analyzeProposal(uint256 proposalId, uint256 requestedFunding) external onlyOwner returns (uint256 impactScore, bool recommendFunding) {
        (uint256 futureRevenue, uint256 futureStaking, uint256 inflationRisk) = economicPredictor.predictEconomicTrends();
        
        impactScore = (futureRevenue + futureStaking) / (inflationRisk + 1); // AI-based impact calculation
        recommendFunding = impactScore > 1000; // Arbitrary threshold

        emit ProposalAnalyzed(proposalId, impactScore, recommendFunding);
        return (impactScore, recommendFunding);
    }
}

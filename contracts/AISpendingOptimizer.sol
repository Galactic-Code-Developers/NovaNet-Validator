// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AITreasuryBrain.sol";

contract AISpendingOptimizer is Ownable {
    AITreasuryBrain public treasuryBrain;
    
    event FundAllocationAdjusted(uint256 adjustedAmount);

    constructor(address _treasuryBrain) {
        treasuryBrain = AITreasuryBrain(_treasuryBrain);
    }

    function optimizeSpending(uint256 requestedAmount) external onlyOwner returns (uint256) {
        (uint256 revenue, uint256 expenses, ) = treasuryBrain.getLatestTreasuryData();
        uint256 availableFunds = revenue - expenses;
        uint256 optimizedAmount = availableFunds > requestedAmount ? requestedAmount : availableFunds;

        emit FundAllocationAdjusted(optimizedAmount);
        return optimizedAmount;
    }
}

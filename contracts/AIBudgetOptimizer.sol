// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AITreasurySimulator.sol";

contract AIBudgetOptimizer is Ownable {
    AITreasurySimulator public treasurySimulator;
    uint256 public minReserveThreshold;
    uint256 public maxSpendingLimit;

    event BudgetOptimized(uint256 newMinReserve, uint256 newMaxSpending);

    constructor(address _treasurySimulator) {
        treasurySimulator = AITreasurySimulator(_treasurySimulator);
        minReserveThreshold = 5000 ether; // Default value
        maxSpendingLimit = 2000 ether; // Default value
    }

    function optimizeBudget(uint256 volatilityFactor) external onlyOwner {
        AITreasurySimulator.TreasuryProjection memory projection = treasurySimulator.getLatestProjection();

        uint256 adjustedMinReserve = projection.projectedReserves / volatilityFactor;
        uint256 adjustedMaxSpending = projection.projectedRevenue / 2;

        minReserveThreshold = adjustedMinReserve;
        maxSpendingLimit = adjustedMaxSpending;

        emit BudgetOptimized(adjustedMinReserve, adjustedMaxSpending);
    }

    function getBudgetLimits() external view returns (uint256, uint256) {
        return (minReserveThreshold, maxSpendingLimit);
    }
}

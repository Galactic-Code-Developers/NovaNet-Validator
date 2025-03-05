// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AITreasurySimulator is Ownable {
    struct TreasuryProjection {
        uint256 projectedRevenue;
        uint256 projectedExpenses;
        uint256 projectedReserves;
        uint256 simulationTimestamp;
    }

    TreasuryProjection public latestProjection;

    event TreasurySimulationUpdated(
        uint256 projectedRevenue,
        uint256 projectedExpenses,
        uint256 projectedReserves,
        uint256 timestamp
    );

    function simulateFutureTreasury(
        uint256 currentReserves,
        uint256 avgRevenueGrowthRate,
        uint256 avgExpenseGrowthRate
    ) external onlyOwner {
        uint256 newRevenue = (currentReserves * avgRevenueGrowthRate) / 100;
        uint256 newExpenses = (currentReserves * avgExpenseGrowthRate) / 100;
        uint256 newReserves = currentReserves + newRevenue - newExpenses;

        latestProjection = TreasuryProjection(newRevenue, newExpenses, newReserves, block.timestamp);
        emit TreasurySimulationUpdated(newRevenue, newExpenses, newReserves, block.timestamp);
    }

    function getLatestProjection() external view returns (TreasuryProjection memory) {
        return latestProjection;
    }
}

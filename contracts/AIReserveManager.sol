// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AIBudgetOptimizer.sol";

contract AIReserveManager is Ownable {
    AIBudgetOptimizer public budgetOptimizer;
    uint256 public reserveBalance;

    event ReserveAdjusted(uint256 newReserveBalance);

    constructor(address _budgetOptimizer, uint256 initialReserve) {
        budgetOptimizer = AIBudgetOptimizer(_budgetOptimizer);
        reserveBalance = initialReserve;
    }

    function adjustReserves(uint256 deposit, uint256 withdrawal) external onlyOwner {
        (, uint256 maxSpending) = budgetOptimizer.getBudgetLimits();

        require(withdrawal <= maxSpending, "Withdrawal exceeds AI-defined spending limit");
        reserveBalance = reserveBalance + deposit - withdrawal;

        emit ReserveAdjusted(reserveBalance);
    }

    function getReserveBalance() external view returns (uint256) {
        return reserveBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AITreasuryBrain.sol";

contract AIEconomicPredictor is Ownable {
    AITreasuryBrain public treasuryBrain;

    event PredictionGenerated(uint256 futureRevenue, uint256 futureStaking, uint256 inflationRisk);

    constructor(address _treasuryBrain) {
        treasuryBrain = AITreasuryBrain(_treasuryBrain);
    }

    function predictEconomicTrends() external view returns (uint256 futureRevenue, uint256 futureStaking, uint256 inflationRisk) {
        (uint256 revenue, uint256 expenses, uint256 stakingParticipation) = treasuryBrain.getLatestTreasuryData();
        futureRevenue = revenue * 105 / 100; // Assume 5% growth
        futureStaking = stakingParticipation * 103 / 100; // Assume 3% growth
        inflationRisk = expenses > revenue ? (expenses - revenue) * 100 / revenue : 0;

        return (futureRevenue, futureStaking, inflationRisk);
    }
}

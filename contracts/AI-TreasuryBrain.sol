// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AITreasuryBrain is Ownable {
    struct TreasuryRecord {
        uint256 timestamp;
        uint256 revenue;
        uint256 expenses;
        uint256 stakingParticipation;
    }

    TreasuryRecord[] public treasuryRecords;

    event TreasuryDataUpdated(uint256 indexed timestamp, uint256 revenue, uint256 expenses, uint256 stakingParticipation);

    function recordTreasuryData(uint256 _revenue, uint256 _expenses, uint256 _stakingParticipation) external onlyOwner {
        treasuryRecords.push(TreasuryRecord(block.timestamp, _revenue, _expenses, _stakingParticipation));
        emit TreasuryDataUpdated(block.timestamp, _revenue, _expenses, _stakingParticipation);
    }

    function getLatestTreasuryData() external view returns (uint256 revenue, uint256 expenses, uint256 stakingParticipation) {
        require(treasuryRecords.length > 0, "No treasury data available");
        TreasuryRecord storage latest = treasuryRecords[treasuryRecords.length - 1];
        return (latest.revenue, latest.expenses, latest.stakingParticipation);
    }
}

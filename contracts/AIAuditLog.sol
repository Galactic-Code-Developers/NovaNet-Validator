// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AIAuditLog {
    struct LogEntry {
        uint256 timestamp;
        string action;
        address actor;
    }

    LogEntry[] public logs;

    event LogAdded(uint256 indexed timestamp, string action, address indexed actor);

    function addLog(string memory _action) external {
        logs.push(LogEntry(block.timestamp, _action, msg.sender));
        emit LogAdded(block.timestamp, _action, msg.sender);
    }

    function getLogs() external view returns (LogEntry[] memory) {
        return logs;
    }
}

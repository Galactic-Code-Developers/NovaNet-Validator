// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIAuditLogger is Ownable {
    struct AuditLog {
        uint256 timestamp;
        string action;
        uint256 amount;
        address executor;
    }

    AuditLog[] public auditLogs;

    event AuditLogged(uint256 timestamp, string action, uint256 amount, address indexed executor);

    function logAudit(string memory action, uint256 amount, address executor) external onlyOwner {
        auditLogs.push(AuditLog(block.timestamp, action, amount, executor));
        emit AuditLogged(block.timestamp, action, amount, executor);
    }

    function getAuditLogs() external view returns (AuditLog[] memory) {
        return auditLogs;
    }
}

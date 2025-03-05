// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AISlashingMonitor.sol";
import "./NovaNetValidator.sol";

contract AISlashingEnforcer {
    AISlashingMonitor public monitor;
    NovaNetValidator public validatorContract;

    event ValidatorSlashed(address indexed validator, uint256 slashedAmount);

    constructor(address _monitor, address _validatorContract) {
        monitor = AISlashingMonitor(_monitor);
        validatorContract = NovaNetValidator(_validatorContract);
    }

    function slashValidator(address _validator) external {
        require(monitor.reports(_validator).confirmed, "Misconduct not confirmed");
        uint256 slashedAmount = calculateSlashingAmount(monitor.reports(_validator).severity, _validator);
        validatorContract.slashValidator(_validator, slashedAmount);
        emit ValidatorSlashed(_validator, slashedAmount);
    }

    function calculateSlashingAmount(uint256 severity, address validator) internal view returns (uint256) {
        uint256 stake = validatorContract.getValidatorStake(validator);
        return (stake * severity) / 100; // Slashes percentage of stake based on severity
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovaNetValidator.sol";
import "./DelegatorContract.sol";
import "./Governance.sol";

contract Slashing is Ownable {
    struct SlashRecord {
        address validator;
        uint256 slashedAmount;
        string reason;
        uint256 timestamp;
    }

    NovaNetValidator public validatorContract;
    DelegatorContract public delegatorContract;
    Governance public governanceContract;
    
    mapping(address => uint256) public validatorPenalties;
    mapping(uint256 => SlashRecord) public slashHistory;
    uint256 public slashCount;

    event ValidatorSlashed(address indexed validator, uint256 amount, string reason);
    event ValidatorRemoved(address indexed validator, string reason);

    modifier onlyGovernance() {
        require(msg.sender == address(governanceContract), "Not authorized: Governance only");
        _;
    }

    constructor(address _validatorContract, address _delegatorContract, address _governance) {
        validatorContract = NovaNetValidator(_validatorContract);
        delegatorContract = DelegatorContract(_delegatorContract);
        governanceContract = Governance(_governance);
    }

    function slashValidator(address _validator, uint256 _amount, string memory _reason) external onlyGovernance {
        require(validatorContract.isValidator(_validator), "Address is not a validator");
        
        uint256 stake = validatorContract.getValidatorStake(_validator);
        require(_amount <= stake, "Slashing amount exceeds stake");

        // Reduce validator's stake
        validatorContract.reduceStake(_validator, _amount);
        
        // Record the slashing event
        slashCount++;
        slashHistory[slashCount] = SlashRecord({
            validator: _validator,
            slashedAmount: _amount,
            reason: _reason,
            timestamp: block.timestamp
        });

        validatorPenalties[_validator] += _amount;
        emit ValidatorSlashed(_validator, _amount, _reason);

        // If stake drops below threshold, remove validator
        if (validatorContract.getValidatorStake(_validator) < validatorContract.getMinStake()) {
            removeValidator(_validator, "Insufficient stake after slashing");
        }
    }

    function removeValidator(address _validator, string memory _reason) internal {
        validatorContract.removeValidator(_validator);
        emit ValidatorRemoved(_validator, _reason);
    }

    function slashForDowntime(address _validator) external {
        require(validatorContract.getUptime(_validator) < 90, "Validator uptime is acceptable");

        uint256 penalty = (validatorContract.getValidatorStake(_validator) * 5) / 100; // 5% stake penalty
        slashValidator(_validator, penalty, "Low uptime");
    }

    function slashForDoubleSigning(address _validator) external {
        require(validatorContract.detectDoubleSigning(_validator), "No double signing detected");

        uint256 penalty = (validatorContract.getValidatorStake(_validator) * 10) / 100; // 10% stake penalty
        slashValidator(_validator, penalty, "Double signing detected");
    }

    function getSlashingHistory(uint256 _id) external view returns (address, uint256, string memory, uint256) {
        SlashRecord storage record = slashHistory[_id];
        return (record.validator, record.slashedAmount, record.reason, record.timestamp);
    }
}

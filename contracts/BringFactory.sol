// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BringDrop.sol";

contract BringFactory is Ownable {
    using Clones for address;

    address public immutable dropImplementation;
    address public reclaimAddress; // reclaim contract address to verify proofs
    address public feeRecipient;
    uint256 public feeAmount; // Fee percentage in basis points (e.g., 30 = 0.3%)
    
    event DropCreated(address indexed dropAddress, address indexed bringer, address indexed token, uint256 amount, uint256 maxClaims);
    event FeeUpdated(uint256 newFeeAmount);
    event FeeRecipientUpdated(address newFeeRecipient);
    
    constructor(address _reclaimAddress, address _feeRecipient, uint256 _feeAmount) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_feeAmount <= 100, "Fee cannot exceed 1%");
        
        dropImplementation = address(new BringDrop());
        reclaimAddress = _reclaimAddress;
        feeRecipient = _feeRecipient;
        feeAmount = _feeAmount;
    }

    function setFee(uint256 _feeAmount) external onlyOwner {
        require(_feeAmount <= 100, "Fee cannot exceed 1%");
        feeAmount = _feeAmount;
        emit FeeUpdated(_feeAmount);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }
    
    function createDrop(
        address _token,
        uint256 _amount,
        uint256 _maxClaims,
        string[] memory _providersHashes
    ) external {
        address clone = dropImplementation.clone();
        BringDrop(clone).initialize(msg.sender, _token, _amount, _maxClaims, _providersHashes, reclaimAddress, feeRecipient, feeAmount);
        emit DropCreated(clone, msg.sender, _token, _amount, _maxClaims);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@reclaimprotocol/verifier-solidity-sdk/contracts/Reclaim.sol";
import "@reclaimprotocol/verifier-solidity-sdk/contracts/Addresses.sol";

contract Drop {
    address public token;
    uint256 public amount;
    uint256 public maxClaims;
    uint256 public claimed;
    address public reclaimAddress;
    address public dropper;
    address public feeRecipient;
    uint256 public feeAmount; // Fee percentage in basis points

    mapping(bytes32 => bool) public usedReclaimProofs;
    string[] public providersHashes;
    bool private initialized;

    event Claimed(address indexed destination, bytes32 reclaimProof);

    function initialize(
                        address _dropper,
                        address _token,
                        uint256 _amount,
                        uint256 _maxClaims,
                        string[] memory _providersHashes,
                        address _reclaimAddress,
                        address _feeRecipient,
                        uint256 _feeAmount
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;

        token = _token;
        amount = _amount;
        maxClaims = _maxClaims;
        claimed = 0;
        dropper = _dropper;
        feeRecipient = _feeRecipient;
        feeAmount = _feeAmount;
        
        providersHashes = _providersHashes;
        reclaimAddress = _reclaimAddress;
    }

    function claim(address destination, Reclaim.Proof memory reclaimProof) external {
        bytes32 proofHash = keccak256(abi.encode(reclaimProof));
        require(!usedReclaimProofs[proofHash], "Proof already used");
        require(claimed < maxClaims, "Max claims reached");

        
        // Verify the reclaimProof
        Reclaim(reclaimAddress).verifyProof(reclaimProof, providersHashes);

        // Calculate fee
        uint256 fee = (amount * feeAmount) / 10000;
        uint256 amountAfterFee = amount - fee;

        usedReclaimProofs[proofHash] = true;
        claimed++;       
        
        // Transfer fee to the fee recipient
        TransferHelper.safeTransferFrom(token, dropper, feeRecipient, fee);

        // Transfer remaining amount to the destination
        TransferHelper.safeTransferFrom(token, dropper, destination, amountAfterFee);
        
        emit Claimed(destination, proofHash);        
    }
}

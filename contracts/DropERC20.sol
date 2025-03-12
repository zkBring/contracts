// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DropERC20 is Ownable {
    using ECDSA for bytes32;

    // Drop configuration
    address public token;
    uint256 public amount;       // Amount per claim
    uint256 public totalClaims;  // Maximum number of claims allowed
    uint256 public claimedCount;
    bytes32 public zkPassTaskId;
    bytes32 public zkPassSchemaId;
    bool public stopped;

    // Mapping to track claimed unique identifiers (uHash)
    mapping(bytes32 => bool) public claimed;

    // Fixed expected allocator address from zkPass documentation.
    address public constant EXPECTED_ALLOCATOR_ADDRESS = 0x19a567b3b212a5b35bA0E3B600FbEd5c2eE9083d;

    event Claimed(bytes32 indexed uHash, address recipient);
    event Stopped();

    /**
     * @notice Constructor sets the drop parameters and transfers ownership to the creator.
     * @param _creator The address of the drop creator.
     * @param _token The ERC20 token to be dropped.
     * @param _amount The amount of tokens per claim.
     * @param _totalClaims The total number of claims allowed.
     * @param _zkPassTaskId The zkPass task identifier.
     * @param _zkPassSchemaId The zkPass schema identifier.
     */
    constructor(
        address _creator,
        address _token,
        uint256 _amount,
        uint256 _totalClaims,
        bytes32 _zkPassTaskId,
        bytes32 _zkPassSchemaId
    ) {
        token = _token;
        amount = _amount;
        totalClaims = _totalClaims;
        zkPassTaskId = _zkPassTaskId;
        zkPassSchemaId = _zkPassSchemaId;
        // Set the owner to the drop creator.
        _transferOwnership(_creator);
    }

    modifier notStopped() {
        require(!stopped, "Campaign stopped");
        _;
    }

    /**
     * @notice Claim tokens using a zkPass zkTLS proof.
     * @param validatorAddress The validator address provided by the allocator.
     * @param uHash Unique identifier for the claimer.
     * @param publicFieldsHash Hash of the public fields from the proof.
     * @param recipient The address to receive the tokens.
     * @param allocatorSignature Signature from the allocator.
     * @param validatorSignature Signature from the validator.
     */
    function claim(
        address validatorAddress,
        bytes32 uHash,
        bytes32 publicFieldsHash,
        address recipient,
        bytes memory allocatorSignature,
        bytes memory validatorSignature
    ) external notStopped {
        require(!claimed[uHash], "Already claimed");
        require(claimedCount < totalClaims, "All claims exhausted");

        // Verify allocator signature.
        // Encoded message: [zkPassTaskId, zkPassSchemaId, validatorAddress]
        bytes memory allocatorData = abi.encode(zkPassTaskId, zkPassSchemaId, validatorAddress);
        bytes32 allocatorHash = keccak256(allocatorData).toEthSignedMessageHash();
        address recoveredAllocator = allocatorHash.recover(allocatorSignature);
        require(recoveredAllocator == EXPECTED_ALLOCATOR_ADDRESS, "Invalid allocator signature");

        // Verify validator signature.
        // Encoded message: [zkPassTaskId, zkPassSchemaId, uHash, publicFieldsHash, recipient]
        bytes memory validatorData = abi.encode(zkPassTaskId, zkPassSchemaId, uHash, publicFieldsHash, recipient);
        bytes32 validatorHash = keccak256(validatorData).toEthSignedMessageHash();
        address recoveredValidator = validatorHash.recover(validatorSignature);
        require(recoveredValidator == validatorAddress, "Invalid validator signature");

        // Mark the claim as used.
        claimed[uHash] = true;
        claimedCount++;

        // Transfer tokens from the contract's balance to the recipient.
        require(IERC20(token).transfer(recipient, amount), "Token transfer failed");

        emit Claimed(uHash, recipient);
    }

    /**
     * @notice Check if a claim with the given unique identifier has been made.
     * @param uHash Unique claim identifier.
     * @return True if already claimed, false otherwise.
     */
    function isClaimed(bytes32 uHash) external view returns (bool) {
        return claimed[uHash];
    }

    /**
     * @notice Stop the drop campaign and return all tokens held by the contract to the owner.
     * Can only be called by the owner.
     */
    function stop() external onlyOwner notStopped {
        stopped = true;
        uint256 remaining = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(owner(), remaining), "Token transfer failed");
        emit Stopped();
    }
}

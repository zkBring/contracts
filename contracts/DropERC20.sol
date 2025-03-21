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
    uint256 public maxClaims;  // Maximum number of claims allowed
    uint256 public claims;       // Current number of claims
    bytes32 public zkPassSchemaId;
    bool public stopped;
    uint256 public expiration;    // Expiration timestamp
    bytes32 public metadataIpfsHash;

    // Mapping to track claimed unique identifiers (uHash)
    mapping(bytes32 => bool) public claimed;

    // Fixed expected allocator address from zkPass documentation.
    address public constant EXPECTED_ALLOCATOR_ADDRESS = 0x19a567b3b212a5b35bA0E3B600FbEd5c2eE9083d;

    event Claimed(address indexed recipient, bytes32 uHash);
    event Stopped();

    /**
     * @notice Constructor sets the drop parameters and transfers ownership to the creator.
     * @param _creator The address of the drop creator.
     * @param _token The ERC20 token to be dropped.
     * @param _amount The amount of tokens per claim.
     * @param _maxClaims The total number of claims allowed.
     * @param _zkPassSchemaId The zkPass schema identifier.
     * @param _expiration The expiration timestamp for the drop.
     * @param _metadataIpfsHash Metadata for the drop (title, description).     
     */
    constructor(
        address _creator,
        address _token,
        uint256 _amount,
        uint256 _maxClaims,
        bytes32 _zkPassSchemaId,
        uint256 _expiration,
        bytes32 _metadataIpfsHash        
    ) {
        token = _token;
        amount = _amount;
        maxClaims = _maxClaims;
        zkPassSchemaId = _zkPassSchemaId;
        expiration = _expiration;
        metadataIpfsHash = _metadataIpfsHash;
        
        // Set the owner to the drop creator.
        _transferOwnership(_creator);
    }

    modifier notStopped() {
        require(!stopped, "Campaign stopped");
        _;
    }

    modifier notExpired() {
        require(block.timestamp < expiration, "Drop has expired");
        _;
    }

    /**
     * @notice Claim tokens with ephemeral key using a zkPass zkTLS proof.
     * @param zkPassTaskId The zkPass task identifier.
     * @param validatorAddress The validator address provided by the allocator.
     * @param uHash Unique identifier for the claimer.
     * @param publicFieldsHash Hash of the public fields from the proof.
     * @param recipient The address to receive the tokens.
     * @param ephemeralKeyAddress The address corresponding to ephemeral key
     * @param ephemeralKeySignature Signature from the claim key authorizing.     
     * @param allocatorSignature Signature from the allocator.
     * @param validatorSignature Signature from the validator.
     */
    function claimWithEphemeralKey(
        bytes32 zkPassTaskId,
        address validatorAddress,
        bytes32 uHash,
        bytes32 publicFieldsHash,
        address recipient,
        address ephemeralKeyAddress,
        bytes memory ephemeralKeySignature,
        bytes memory allocatorSignature,
        bytes memory validatorSignature
    ) external {
        
        // Verify ephemeral signature.
        require(verifyEphemeralKeySignature(recipient, ephemeralKeyAddress, ephemeralKeySignature), "Invalid ephemeral key signature");           
        
        _claim(zkPassTaskId,
               validatorAddress,
               uHash,
               publicFieldsHash,
               recipient,
               ephemeralKeyAddress,
               allocatorSignature,
               validatorSignature);
    }

    /**
     * @notice Claim tokens using a zkPass zkTLS proof.
     * @param zkPassTaskId The zkPass task identifier.
     * @param validatorAddress The validator address provided by the allocator.
     * @param uHash Unique identifier for the claimer.
     * @param publicFieldsHash Hash of the public fields from the proof.
     * @param recipient The address to receive the tokens.
     * @param allocatorSignature Signature from the allocator.
     * @param validatorSignature Signature from the validator.
     */
    function claim(
        bytes32 zkPassTaskId,
        address validatorAddress,
        bytes32 uHash,
        bytes32 publicFieldsHash,
        address recipient,
        bytes memory allocatorSignature,
        bytes memory validatorSignature
    ) external {        
        _claim(zkPassTaskId,
               validatorAddress,
               uHash,
               publicFieldsHash,
               recipient,
               recipient,
               allocatorSignature,
               validatorSignature);
    }

    
    function _claim(
        bytes32 zkPassTaskId,
        address validatorAddress,
        bytes32 uHash,
        bytes32 publicFieldsHash,
        address recipient,
        address ephemeralKeyAddress,
        bytes memory allocatorSignature,
        bytes memory validatorSignature
) private notStopped notExpired {
        require(!claimed[uHash], "Already claimed");
        require(claims < maxClaims, "All claims exhausted");

        // Verify allocator signature.
        require(verifyAllocatorSignature(zkPassTaskId, validatorAddress, allocatorSignature), "Invalid allocator signature");
        
        // Verify validator signature.
        require(verifyValidatorSignature(zkPassTaskId, uHash, publicFieldsHash, ephemeralKeyAddress, validatorAddress, validatorSignature), "Invalid validator signature");

        // Mark the claim as used.
        claimed[uHash] = true;
        claims++;

        // Transfer tokens from the contract's balance to the recipient.
        require(IERC20(token).transfer(recipient, amount), "Token transfer failed");

        emit Claimed(recipient, uHash);
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

    function verifyAllocatorSignature(
        bytes32 zkPassTaskId, 
        address validatorAddress,
        bytes memory allocatorSignature
    ) public view returns (bool) {
        bytes memory allocatorData = abi.encode(zkPassTaskId, zkPassSchemaId, validatorAddress);
        bytes32 allocatorHash = keccak256(allocatorData).toEthSignedMessageHash();
        address recoveredAllocator = allocatorHash.recover(allocatorSignature);
        return (recoveredAllocator == EXPECTED_ALLOCATOR_ADDRESS);
    }

    function verifyValidatorSignature(
        bytes32 zkPassTaskId,
        bytes32 uHash,
        bytes32 publicFieldsHash,
        address recipient,
        address validatorAddress,
        bytes memory validatorSignature
    ) public view returns (bool) {
        bytes memory validatorData = abi.encode(zkPassTaskId, zkPassSchemaId, uHash, publicFieldsHash, recipient);
        bytes32 validatorHash = keccak256(validatorData).toEthSignedMessageHash();
        address recoveredValidator = validatorHash.recover(validatorSignature);
        return (recoveredValidator == validatorAddress);
    }

    function verifyEphemeralKeySignature(
                                         address recipient,
                                         address ephemeralKeyAddress,
                                         bytes memory ephemeralKeySignature
    ) public pure returns (bool) {
        bytes memory ephemeralKeyData = abi.encode(recipient);
        bytes32 ephemeralKeyHash = keccak256(ephemeralKeyData).toEthSignedMessageHash();
        address recoveredEphemeralKey = ephemeralKeyHash.recover(ephemeralKeySignature);
        return (recoveredEphemeralKey == ephemeralKeyAddress);        
    }
}

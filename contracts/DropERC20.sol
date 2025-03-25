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
    address public constant EXPECTED_ALLOCATOR = 0x19a567b3b212a5b35bA0E3B600FbEd5c2eE9083d;

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
     * @param validator The validator address provided by the allocator.
     * @param uHash Unique identifier for the claimer.
     * @param publicFieldsHash Hash of the public fields from the proof.
     * @param recipient The address to receive the tokens.
     * @param ephemeralKey The address corresponding to ephemeral key
     * @param ephemeralSig Signature from the claim key authorizing.     
     * @param allocatorSig Signature from the allocator.
     * @param validatorSig Signature from the validator.
     */
    function claimWithEphemeralKey(
        bytes32 zkPassTaskId,
        address validator,
        bytes32 uHash,
        bytes32 publicFieldsHash,
        address recipient,
        address ephemeralKey,
        bytes memory ephemeralSig,
        bytes memory allocatorSig,
        bytes memory validatorSig
    ) external {
        
        // Verify ephemeral signature.
        require(verifyEphemeralSignature(recipient, ephemeralKey, ephemeralSig), "Invalid ephemeral key signature");           
        
        _claim(zkPassTaskId,
               validator,
               uHash,
               publicFieldsHash,
               recipient,
               ephemeralKey,
               allocatorSig,
               validatorSig);
    }

    /**
     * @notice Claim tokens using a zkPass zkTLS proof.
     * @param zkPassTaskId The zkPass task identifier.
     * @param validator The validator address provided by the allocator.
     * @param uHash Unique identifier for the claimer.
     * @param publicFieldsHash Hash of the public fields from the proof.
     * @param allocatorSig Signature from the allocator.
     * @param validatorSig Signature from the validator.
     */
    function claim(
        bytes32 zkPassTaskId,
        address validator,
        bytes32 uHash,
        bytes32 publicFieldsHash,
        bytes memory allocatorSig,
        bytes memory validatorSig
    ) external {
        address recipient = msg.sender;
        _claim(zkPassTaskId,
               validator,
               uHash,
               publicFieldsHash,
               recipient,
               recipient,
               allocatorSig,
               validatorSig);
    }

    
    function _claim(
        bytes32 zkPassTaskId,
        address validator,
        bytes32 uHash,
        bytes32 publicFieldsHash,
        address recipient,
        address webproofRecipient,
        bytes memory allocatorSig,
        bytes memory validatorSig
) private notStopped notExpired {
        require(!claimed[uHash], "Already claimed");
        require(claims < maxClaims, "All claims exhausted");

        // Verify allocator signature.
        require(verifyAllocatorSignature(zkPassTaskId, validator, allocatorSig), "Invalid allocator signature");
        
        // Verify validator signature.
        require(verifyValidatorSignature(zkPassTaskId, uHash, publicFieldsHash, webproofRecipient, validator, validatorSig), "Invalid validator signature");

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
        address validator,
        bytes memory allocatorSig
    ) public view returns (bool) {
        bytes memory allocatorData = abi.encode(zkPassTaskId, zkPassSchemaId, validator);
        bytes32 allocatorHash = keccak256(allocatorData).toEthSignedMessageHash();
        address recovered = allocatorHash.recover(allocatorSig);
        return (recovered == EXPECTED_ALLOCATOR);
    }

    function verifyValidatorSignature(
        bytes32 zkPassTaskId,
        bytes32 uHash,
        bytes32 publicFieldsHash,
        address webproofRecipientAddress,
        address validator,
        bytes memory validatorSig
    ) public view returns (bool) {
        bytes memory validatorData = abi.encode(zkPassTaskId, zkPassSchemaId, uHash, publicFieldsHash, webproofRecipientAddress);
        bytes32 validatorHash = keccak256(validatorData).toEthSignedMessageHash();
        address recovered = validatorHash.recover(validatorSig);
        return (recovered == validator);
    }

    function verifyEphemeralSignature(
                                         address recipient,
                                         address ephemeralKey,
                                         bytes memory ephemeralSig
    ) public pure returns (bool) {
        bytes memory ephemeralData = abi.encode(recipient);
        bytes32 ephemeralHash = keccak256(ephemeralData).toEthSignedMessageHash();
        address recovered = ephemeralHash.recover(ephemeralSig);
        return (recovered == ephemeralKey);        
    }

    // Function to compute webproof recipient for epheremeral key
    function computeWpRecipientForEphemeralKey(address ephemeralKey) public view returns (address) {
        // Convert addresses to uint160 (their underlying numeric representation), perform XOR, then cast back to address.
        return address(uint160(address(this)) ^ uint160(ephemeralKey));
    }
}

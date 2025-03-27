// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DropERC20 is Ownable {
    using ECDSA for bytes32;

    // Drop configuration
    address public immutable token;
    uint256 public immutable amount;       // Amount per claim
    uint256 public immutable maxClaims;  // Maximum number of claims allowed
    bytes32 public immutable zkPassSchemaId;
    uint256 public immutable expiration;    // Expiration timestamp
    address public immutable BRING_TOKEN;
    address public immutable ZK_PASS_ALLOCATOR_ADDRESS;  // expected allocator address from zkPass.
    
    uint256 public bringStaked;
    uint256 public claims;       // Current number of claims
    string public metadataIpfsHash;
    bool public stopped;
    
    // Mappings to track claims
    mapping(bytes32 => bool) public claimedUsers; // by uHash from webproof
    mapping(address => bool) public claimedAddresses; // by recipient address
    
    event Claimed(address indexed recipient, bytes32 uHash);
    event MetadataUpdated(string metadataIpfsHash);
    event BringStaked(address bringToken, uint256 amount, uint256 totalStaked);
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
     * @param _bringToken The address of the bring token.
     */
    constructor(
        address _creator,
        address _token,
        uint256 _amount,
        uint256 _maxClaims,
        bytes32 _zkPassSchemaId,
        uint256 _expiration,
        string memory _metadataIpfsHash,
        address _zkPassAllocator,
        address _bringToken
    ) {
        token = _token;
        amount = _amount;
        maxClaims = _maxClaims;
        zkPassSchemaId = _zkPassSchemaId;
        expiration = _expiration;
        metadataIpfsHash = _metadataIpfsHash;
        ZK_PASS_ALLOCATOR_ADDRESS = _zkPassAllocator;
        BRING_TOKEN = _bringToken;
        
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
     * @notice Stake bring tokens. Can be called multiple times to add additional stake.
     * @param _amount The amount of bring tokens to stake.
     */
    function stake(uint256 _amount) external onlyOwner notStopped notExpired {
        require(_amount > 0, "Stake amount must be greater than zero");
        require(
            IERC20(BRING_TOKEN).transferFrom(msg.sender, address(this), _amount),
            "Bring token transfer failed"
        );
        bringStaked += _amount;
        emit BringStaked(BRING_TOKEN, _amount, bringStaked);
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

        // compute recipient address that was provided in the webproof
        address webproofRecipient = computeWpRecipientForEphemeralKey(ephemeralKey);
        
        // Verify ephemeral signature.
        require(verifyEphemeralSignature(recipient, ephemeralKey, ephemeralSig), "Invalid ephemeral key signature");           
        
        _claim(zkPassTaskId,
               validator,
               uHash,
               publicFieldsHash,
               recipient,
               webproofRecipient,
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
        require(!claimedUsers[uHash], "User (uHash) already claimed");
        require(!claimedAddresses[recipient], "User address already claimed");        
        require(claims < maxClaims, "All claims exhausted");

        // Verify allocator signature.
        require(verifyAllocatorSignature(zkPassTaskId, validator, allocatorSig), "Invalid allocator signature");
        
        // Verify validator signature.
        require(verifyValidatorSignature(zkPassTaskId, uHash, publicFieldsHash, webproofRecipient, validator, validatorSig), "Invalid validator signature");

        // Mark the claim as used.
        claimedUsers[uHash] = true;
        claimedAddresses[recipient] = true;        
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
    function hasUserClaimed(bytes32 uHash) external view returns (bool) {
        return claimedUsers[uHash];
    }

    /**
     * @notice Check if a claim with the given unique identifier has been made.
     * @param userAddress Unique claim identifier.
     * @return True if already claimed, false otherwise.
     */
    function hasAddressClaimed(address userAddress) external view returns (bool) {
        return claimedAddresses[userAddress];
    }

    /**
     * @notice Stop the drop campaign and return all tokens held by the contract to the owner.
     * Can only be called by the owner.
     */
    function stop() external onlyOwner notStopped {
        stopped = true;
        uint256 remaining = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(owner(), remaining), "Token transfer failed");
        
        if (bringStaked > 0) {
            uint256 bringBalance = IERC20(BRING_TOKEN).balanceOf(address(this));            
            bringStaked = 0;
            require(IERC20(BRING_TOKEN).transfer(owner(), bringBalance), "Bring token transfer failed");
        }
        
        emit Stopped();
    }

    function updateMetadata(string memory _metadataIpfsHash) external onlyOwner notStopped notExpired {
        metadataIpfsHash = _metadataIpfsHash;
        emit MetadataUpdated(_metadataIpfsHash);
    }
    
    function verifyAllocatorSignature(
        bytes32 zkPassTaskId, 
        address validator,
        bytes memory allocatorSig
    ) public view returns (bool) {
        bytes memory allocatorData = abi.encode(zkPassTaskId, zkPassSchemaId, validator);
        bytes32 allocatorHash = keccak256(allocatorData).toEthSignedMessageHash();
        address recovered = allocatorHash.recover(allocatorSig);
        return (recovered == ZK_PASS_ALLOCATOR_ADDRESS);
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

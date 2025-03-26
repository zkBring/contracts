// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./DropERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DropFactory is Ownable {
    // Fee 0.01 percentage (e.g., 5 means 0.05%)
    uint256 public fee;
    address public feeRecipient;
    address public immutable ZK_PASS_ALLOCATOR_ADDRESS;
    address public immutable BRING_TOKEN;    
    
    event DropCreated(
        address indexed creator,
        address indexed drop,
        address indexed token,
        uint256 amount,
        uint256 maxClaims,
        bytes32 zkPassSchemaId,
        uint256 expiration,
        string metadataIpfsHash        
    );
    event FeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newFeeRecipient);

    constructor(uint256 _fee, address _feeRecipient, address _zkPassAllocator, address _bringToken) {
        fee = _fee;
        feeRecipient = _feeRecipient;
        ZK_PASS_ALLOCATOR_ADDRESS = _zkPassAllocator;
        BRING_TOKEN = _bringToken;
    }

    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    function updateFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /**
     * @notice Create a new ERC20 drop.
     * @param token The ERC20 token address.
     * @param amount The amount of tokens per claim.
     * @param maxClaims The total number of claims allowed.
     * @param zkPassSchemaId The zkPass schema identifier.
     * @param expiration The expiration timestamp for the drop.
     * @param metadataIpfsHash Metadata for the drop (title, description).     
     * @return dropAddress The address of the newly created drop.
     */
    function createDrop(
        address token,
        uint256 amount,
        uint256 maxClaims,
        bytes32 zkPassSchemaId,
        uint256 expiration,
        string memory metadataIpfsHash
    ) external returns (address dropAddress) {
        uint256 totalDistribution = amount * maxClaims;
        uint256 feeAmount = (totalDistribution * fee) / 10000;
        uint256 requiredTotal = totalDistribution + feeAmount;

        // Transfer required tokens from msg.sender to the factory.
        require(
            IERC20(token).transferFrom(msg.sender, address(this), requiredTotal),
            "Token transfer to factory failed"
        );

        // Deploy the drop contract.
        DropERC20 drop = new DropERC20(
            msg.sender,
            token,
            amount,
            maxClaims,
            zkPassSchemaId,
            expiration,
            metadataIpfsHash,
            ZK_PASS_ALLOCATOR_ADDRESS,
            BRING_TOKEN
        );
        dropAddress = address(drop);

        // Transfer fee tokens to feeRecipient.
        require(
            IERC20(token).transfer(feeRecipient, feeAmount),
            "Fee transfer failed"
        );

        // Transfer distribution tokens to the created drop contract.
        require(
            IERC20(token).transfer(dropAddress, totalDistribution),
            "Token transfer to drop failed"
        );

        emit DropCreated(msg.sender, dropAddress, token, amount, maxClaims, zkPassSchemaId, expiration, metadataIpfsHash);
    }
}

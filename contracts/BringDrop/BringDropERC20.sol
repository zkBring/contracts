// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IBringDropERC20.sol";
import "./BringDropCommon.sol";

contract BringDropERC20 is IBringDropERC20, BringDropCommon {
     
    /**
    * @dev Function to verify BringDrop signer's signature
    * @param _token Token address
    * @param _amount Amount of tokens to be claimed (in atomic value)
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _signature ECDSA signature of BringDrop signer
    * @return True if signed with BringDrop signer's private key
    */
    function verifySignerSignature
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        bytes memory _signature
    )
    public view
      override 
    returns (bool)
    {
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash
        (
            keccak256
            (
                abi.encodePacked
                (
                 uint(0),
                 _token,
                 _amount,
                 _expiration,
                 version,
                 block.chainid,
                 _linkId,
                 address(this)
                )
            )
        );
        address recovered = ECDSA.recover(prefixedHash, _signature);
        return recovered == signer;
    }

    /**
    * @dev Function to verify claim params and make sure the link is not claimed or canceled
    * @param _token Token address
    * @param _amount Amount of tokens to be claimed (in atomic value)
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _signerSignature ECDSA signature of Drop signer
    * @param _receiver Address of BringDrop receiver
    * @param _receiverSignature ECDSA signature of drop receiver,
    * @return True if success
    */
    function checkClaimParams
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        bytes memory _signerSignature,
        address _receiver,
        bytes memory _receiverSignature
     )
    public view
    override
        notStopped
    returns (bool)
    {
        // If tokens are being claimed
        require(_token != address(0), "INVALID_TOKEN_ADDRESS");

        // Make sure link is not claimed
        require(isClaimed(_linkId) == false, "LINK_CLAIMED");

        // Make sure link is not expired
        require(_expiration >= block.timestamp, "LINK_EXPIRED");

        // Make sure tokens are available for this contract
        require
            (
             IERC20(_token).balanceOf(address(this)) >= _amount,
             "INSUFFICIENT_TOKENS"
            );
                

        // Verify that link key is legit and signed by BringDrop signer
        require
        (
            verifySignerSignature
            (
                _token,
                _amount,
                _expiration,
                _linkId,
                _signerSignature
            ),
            "BRING_INVALID_SIGNER_SIGNATURE"
        );

        // Verify that receiver address is signed by ephemeral key assigned to claim link (link key)
        require
        (
            verifyReceiverSignature(_linkId, _receiver, _receiverSignature),
            "INVALID_RECEIVER_SIGNATURE"
        );

        return true;
    }

    /**
    * @dev Function to claim ETH and/or ERC20 tokens. Can only be called when contract is not paused
    * @param _token Token address
    * @param _amount Amount of tokens to be claimed (in atomic value)
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _signerSignature ECDSA signature of Drop signer
    * @param _receiver Address of BringDrop receiver
    * @param _receiverSignature ECDSA signature of BringDrop receiver
    * @return True if success
    */
    function claim
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        bytes calldata _signerSignature,
        address _receiver,
        bytes calldata _receiverSignature
    )
    external        
    override
    notStopped
    returns (bool)
    {

        // Make sure params are valid
        require
        (
            checkClaimParams
            (
                _token,
                _amount,
                _expiration,
                _linkId,
                _signerSignature,
                _receiver,
                _receiverSignature
            ),
            "INVALID_CLAIM_PARAMS"
        );

        // Mark link as claimed
        claimedTo[_linkId] = _receiver;

        // Make sure transfer succeeds
        require(_transferFunds(_token, _amount, _receiver), "TRANSFER_FAILED");

        // Emit claim event
        emit Claimed(_linkId, _token, _amount, _receiver);

        return true;
    }


    
    /**
    * @dev Internal function to transfer ethers and/or ERC20 tokens
    * @param _token Token address
    * @param _amount Amount of tokens to be claimed (in atomic value)
    * @param _receiver Address to transfer funds to

    * @return True if success
    */
    function _transferFunds
    (
        address _token,
        uint _amount,
        address _receiver
    )
    internal returns (bool) {
        IERC20(_token).transferFrom(creator, _receiver, _amount);
        return true;
    }
}

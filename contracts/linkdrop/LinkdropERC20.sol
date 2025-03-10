// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILinkdropERC20.sol";
import "./LinkdropCommon.sol";

contract LinkdropERC20 is ILinkdropERC20, LinkdropCommon {
     
    /**
    * @dev Function to verify linkdrop signer's signature
    * @param _tokenAddress Token address
    * @param _tokenAmount Amount of tokens to be claimed (in atomic value)
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _signature ECDSA signature of linkdrop signer
    * @return True if signed with linkdrop signer's private key
    */
    function verifyLinkdropSignerSignature
    (
        address _tokenAddress,
        uint _tokenAmount,
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
                    _tokenAddress,
                    _tokenAmount,
                    _expiration,
                    version,
                    chainId,
                    _linkId,
                    address(this)
                )
            )
        );
        address signer = ECDSA.recover(prefixedHash, _signature);
        return isLinkdropSigner[signer];
    }


    /**
    * @dev Function to verify claim params and make sure the link is not claimed or canceled
    * @param _tokenAddress Token address
    * @param _tokenAmount Amount of tokens to be claimed (in atomic value)
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _linkdropSignerSignature ECDSA signature of linkdrop signer
    * @param _receiver Address of linkdrop receiver
    * @param _receiverSignature ECDSA signature of linkdrop receiver,
    * @return True if success
    */
    function checkClaimParams
    (
        address _tokenAddress,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        bytes memory _linkdropSignerSignature,
        address _receiver,
        bytes memory _receiverSignature
     )
    public view
    override       
    whenNotPaused
    returns (bool)
    {
        // If tokens are being claimed
        require(_tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");

        // Make sure link is not claimed
        require(isClaimedLink(_linkId) == false, "LINK_CLAIMED");

        // Make sure link is not canceled
        require(isCanceledLink(_linkId) == false, "LINK_CANCELED");

        // Make sure link is not expired
        require(_expiration >= block.timestamp, "LINK_EXPIRED");

        // Make sure tokens are available for this contract
        if (_tokenAddress != address(0) && claimPattern != 1) {
            require
            (
                IERC20(_tokenAddress).balanceOf(linkdropMaster) >= _tokenAmount,
                "INSUFFICIENT_TOKENS"
            );

            require
            (
                IERC20(_tokenAddress).allowance(linkdropMaster, address(this)) >= _tokenAmount, "INSUFFICIENT_ALLOWANCE"
            );
        }

        // Verify that link key is legit and signed by linkdrop signer
        require
        (
            verifyLinkdropSignerSignature
            (
                _tokenAddress,
                _tokenAmount,
                _expiration,
                _linkId,
                _linkdropSignerSignature
            ),
            "INVALID_LINKDROP_SIGNER_SIGNATURE"
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
    * @param _tokenAddress Token address
    * @param _tokenAmount Amount of tokens to be claimed (in atomic value)
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _linkdropSignerSignature ECDSA signature of linkdrop signer
    * @param _receiver Address of linkdrop receiver
    * @param _receiverSignature ECDSA signature of linkdrop receiver
    * @return True if success
    */
    function claim
    (
        address _tokenAddress,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature
    )
    external
    override
    payable
    whenNotPaused
    returns (bool)
    {

        // Make sure params are valid
        require
        (
            checkClaimParams
            (
                _tokenAddress,
                _tokenAmount,
                _expiration,
                _linkId,
                _linkdropSignerSignature,
                _receiver,
                _receiverSignature
            ),
            "INVALID_CLAIM_PARAMS"
        );

        // Mark link as claimed
        claimedTo[_linkId] = _receiver;

        // Make sure transfer succeeds
        require(_transferFunds(_tokenAddress, _tokenAmount, _receiver), "TRANSFER_FAILED");

        // Emit claim event
        emit Claimed(_linkId, _tokenAddress, _tokenAmount, _receiver);

        return true;
    }


    
    /**
    * @dev Internal function to transfer ethers and/or ERC20 tokens
    * @param _tokenAddress Token address
    * @param _tokenAmount Amount of tokens to be claimed (in atomic value)
    * @param _receiver Address to transfer funds to

    * @return True if success
    */
    function _transferFunds
    (
        address _tokenAddress,
        uint _tokenAmount,
        address payable _receiver
    )
    internal returns (bool) {
        IERC20(_tokenAddress).transferFrom(linkdropMaster, _receiver, _tokenAmount);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/ILinkdropERC1155.sol";
import "../interfaces/ILinkdropFactoryERC1155.sol";
import "./LinkdropFactoryCommon.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155.sol";

contract LinkdropFactoryERC1155 is ILinkdropFactoryERC1155, LinkdropFactoryCommon {

    /**
    * @dev Function to verify claim params, make sure the link is not claimed or canceled and proxy is allowed to spend token
    * @param _nftAddress NFT address
    * @param _tokenId Token id to be claimed
    * @param _tokenAmount Token id to be claimed
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _linkdropMaster Address corresponding to linkdrop master key
    * @param _campaignId Campaign id
    * @param _linkdropSignerSignature ECDSA signature of linkdrop signer
    * @param _receiver Address of linkdrop receiver
    * @param _receiverSignature ECDSA signature of linkdrop receiver
    * @return True if success
    */
    function checkClaimParamsERC1155
    (
     uint /* _weiAmount */,
        address _nftAddress,
        uint _tokenId,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes memory _linkdropSignerSignature,
        address _receiver,
        bytes memory _receiverSignature
    )
    public
    override
    view
    returns (bool)
    {
        // Make sure proxy contract is deployed
        require(isDeployed(_linkdropMaster, _campaignId), "LINKDROP_PROXY_CONTRACT_NOT_DEPLOYED");

        return ILinkdropERC1155(deployed[salt(_linkdropMaster, _campaignId)]).checkClaimParamsERC1155
        (
            _nftAddress,
            _tokenId,
            _tokenAmount,
            _expiration,
            _linkId,
            _linkdropSignerSignature,
            _receiver,
            _receiverSignature
        );
    }

    /**
    * @dev Function to claim ETH and/or ERC1155 token
    * @param _nftAddress NFT address
    * @param _tokenId Token id to be claimed
    * @param _tokenAmount Token id to be claimed
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _linkdropMaster Address corresponding to linkdrop master key
    * @param _campaignId Campaign id
    * @param _linkdropSignerSignature ECDSA signature of linkdrop signer
    * @param _receiver Address of linkdrop receiver
    * @param _receiverSignature ECDSA signature of linkdrop receiver
    * @return True if success
    */
    function claimERC1155
        (
        uint /* weiAmount */, 
        address _nftAddress,
        uint _tokenId,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature
    )
    external
    override
    returns (bool)
    {
      
      // Make sure proxy contract is deployed
      require(isDeployed(_linkdropMaster, _campaignId), "LINKDROP_PROXY_CONTRACT_NOT_DEPLOYED");
      
      // Call claim function in the context of proxy contract
      ILinkdropERC1155(deployed[salt(_linkdropMaster, _campaignId)]).claimERC1155
        (
         _nftAddress,
         _tokenId,
         _tokenAmount,
         _expiration,
         _linkId,
         _linkdropSignerSignature,
         _receiver,
         _receiverSignature
       );

      return true;
    }
}

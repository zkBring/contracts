// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/IBringDropERC20.sol";
import "./BringFactoryCommon.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract BringFactoryERC20 is BringFactoryCommon {

    /**
    * @dev Function to verify claim params, make sure the link is not claimed or canceled and proxy has sufficient balance
    * @param _token Token address
    * @param _amount Amount of tokens to be claimed (in atomic value)
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _dropCreator Address corresponding to BringDrop master key
    * @param _campaignId Campaign id
    * @param _dropSignerSignature ECDSA signature of BringDrop signer
    * @param _receiver Address of BringDrop receiver
    * @param _receiverSignature ECDSA signature of BringDrop receiver
    * @return True if success
    */
    function checkClaimParams
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        address _dropCreator,
        uint _campaignId,
        bytes memory _dropSignerSignature,
        address _receiver,
        bytes memory _receiverSignature
    )
    public
    view
    returns (bool)
    {
        // Make sure proxy contract is deployed
        require(isDeployed(_dropCreator, _campaignId), "BRINGDROP_PROXY_CONTRACT_NOT_DEPLOYED");
        IBringDropERC20 drop = IBringDropERC20(deployed[salt(_dropCreator, _campaignId)]);        
        return drop.checkClaimParams
        (
            _token,
            _amount,
            _expiration,
            _linkId,
            _dropSignerSignature,
            _receiver,
            _receiverSignature
        );
    }

    /**
    * @dev Function to claim ETH and/or ERC20 tokens
    * @param _token Token address
    * @param _amount Amount of tokens to be claimed (in atomic value)
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _dropCreator Address corresponding to BringDrop master key
    * @param _campaignId Campaign id
    * @param _dropSignerSignature ECDSA signature of BringDrop signer
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
        address _dropCreator,
        uint _campaignId,
        bytes calldata _dropSignerSignature,
        address _receiver,
        bytes calldata _receiverSignature
    )
    external
    returns (bool)
    {
        // Make sure proxy contract is deployed
        require(isDeployed(_dropCreator, _campaignId), "BRINGDROP_PROXY_CONTRACT_NOT_DEPLOYED");
        IBringDropERC20 drop = IBringDropERC20(deployed[salt(_dropCreator, _campaignId)]);
        // Call claim function in the context of proxy contract
        drop.claim
          (
           _token,
           _amount,
           _expiration,
            _linkId,
           _dropSignerSignature,
           _receiver,
           _receiverSignature
           );
          
          return true;
    }   
}

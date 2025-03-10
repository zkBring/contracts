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
    * @param _creator Address corresponding to BringDrop master key
    * @param _signer Drop Signer
    * @param _signerSig ECDSA signature of BringDrop signer
    * @param _receiver Address of BringDrop receiver
    * @param _receiverSig ECDSA signature of BringDrop receiver
    * @return True if success
    */
    function checkClaimParams
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        address _creator,
        address _signer,
        bytes memory _signerSig,
        address _receiver,
        bytes memory _receiverSig
    )
    public
    view
    returns (bool)
    {
        // Make sure proxy contract is deployed
        require(isDeployed(_creator, _signer), "BRING_DROP_CONTRACT_NOT_DEPLOYED");
        IBringDropERC20 drop = IBringDropERC20(deployed[salt(_creator, _signer)]);        
        return drop.checkClaimParams
        (
            _token,
            _amount,
            _expiration,
            _linkId,
            _signerSig,
            _receiver,
            _receiverSig
        );
    }

    /**
    * @dev Function to claim ETH and/or ERC20 tokens
    * @param _token Token address
    * @param _amount Amount of tokens to be claimed (in atomic value)
    * @param _expiration Unix timestamp of link expiration time
    * @param _linkId Address corresponding to link key
    * @param _creator Drop Creator
    * @param _signer Drop Signer
    * @param _signerSig ECDSA signature of Drop signer
    * @param _receiver Address of BringDrop receiver
    * @param _receiverSig ECDSA signature of drop receiver
    * @return True if success
    */
    function claim
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        address _creator,
        address _signer,
        bytes calldata _signerSig,
        address _receiver,
        bytes calldata _receiverSig
    )
    external
    returns (bool)
    {
        // Make sure proxy contract is deployed
        require(isDeployed(_creator, _signer), "BRING_DROP_CONTRACT_NOT_DEPLOYED");
        IBringDropERC20 drop = IBringDropERC20(deployed[salt(_creator, _signer)]);
        // Call claim function in the context of proxy contract
        drop.claim
          (
           _token,
           _amount,
           _expiration,
            _linkId,
           _signerSig,
           _receiver,
           _receiverSig
           );
          
          return true;
    }   
}

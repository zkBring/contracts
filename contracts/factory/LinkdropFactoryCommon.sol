// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../storage/LinkdropFactoryStorage.sol";
import "../interfaces/ILinkdropCommon.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";

contract LinkdropFactoryCommon is LinkdropFactoryStorage {
    /**
    * @dev Indicates whether a proxy contract for linkdrop master is deployed or not
    * @param _linkdropMaster Address of linkdrop master
    * @param _campaignId Campaign id
    * @return True if deployed
    */
    function isDeployed(address _linkdropMaster, uint _campaignId) public view returns (bool) {
        return (deployed[salt(_linkdropMaster, _campaignId)] != address(0));
    }

    /**
    * @dev Indicates whether a link is claimed or not
    * @param _linkdropMaster Address of lindkrop master
    * @param _campaignId Campaign id
    * @param _linkId Address corresponding to link key
    * @return True if claimed
    */
    function isClaimedLink(address _linkdropMaster, uint _campaignId, address _linkId) public view returns (bool) {

        if (!isDeployed(_linkdropMaster, _campaignId)) {
            return false;
        }
        else {
            address proxy = address(uint160(deployed[salt(_linkdropMaster, _campaignId)]));
            return ILinkdropCommon(proxy).isClaimedLink(_linkId);
        }
    }

    /**
    * @dev Function to deploy a proxy contract for msg.sender and add a new signing key
    * @param _campaignId Campaign id
    * @param _signer Address corresponding to signing key
    * @param _claimPattern which pattern the campaign will use (mint on claim, transfer pre-minted tokens, etc)
    * @return proxy Proxy contract address
    */
    function deployProxyWithSigner(uint _campaignId, address _signer, uint _claimPattern)
    public
    returns (address proxy)
    {
        proxy = _deployProxy(msg.sender, _campaignId, _claimPattern);
        ILinkdropCommon(proxy).addSigner(_signer);
    }

    /**
    * @dev Internal function to deploy a proxy contract for linkdrop master
    * @param _linkdropMaster Address of linkdrop master
    * @param _campaignId Campaign id
    * @param _claimPattern which pattern the campaign will use (mint on claim, transfer pre-minted tokens, etc)
    * @return proxy Proxy contract address
    */
    function _deployProxy(address _linkdropMaster, uint _campaignId, uint _claimPattern)
    internal
    returns (address proxy)
    {

        require(!isDeployed(_linkdropMaster, _campaignId), "LINKDROP_PROXY_CONTRACT_ALREADY_DEPLOYED");
        require(_linkdropMaster != address(0), "INVALID_LINKDROP_MASTER_ADDRESS");

        bytes32 salt = salt(_linkdropMaster, _campaignId);
        bytes memory initcode = getInitcode();

        assembly {
            proxy := create2(0, add(initcode, 0x20), mload(initcode), salt)
            if iszero(extcodesize(proxy)) { revert(0, 0) }
        }

        deployed[salt] = proxy;

        // Initialize factory address, linkdrop master address master copy version in proxy contract
        require
        (
            ILinkdropCommon(proxy).initialize
            (
                address(this), // factory address
                _linkdropMaster, // Linkdrop master address
                masterCopyVersion,
                chainId,
                _claimPattern
            ),
            "INITIALIZATION_FAILED"
        );


        emit Deployed(_linkdropMaster, _campaignId, proxy, salt);
        return proxy;
    }


    /**
    * @dev Function to get bootstrap initcode for generating repeatable contract addresses
    * @return Static bootstrap initcode
    */
    function getInitcode()
    public view
    returns (bytes memory)
    {
        return _initcode;
    }

    /**
    * @dev Function to fetch the actual contract bytecode to install. Called by proxy when executing initcode
    * @return Contract bytecode to install
    */
    function getBytecode()
    public view
    returns (bytes memory)
    {
        return _bytecode;
    }

    /**
    * @dev Function to set new master copy and update contract bytecode to install. Can only be called by factory owner
    * @param _masterCopy Address of linkdrop mastercopy contract to calculate bytecode from
    * @return True if updated successfully
    */
    function setMasterCopy(address _masterCopy)
    public onlyOwner
    returns (bool)
    {
        require(_masterCopy != address(0), "INVALID_MASTER_COPY_ADDRESS");
        masterCopyVersion = masterCopyVersion + 1;

        require
        (
            ILinkdropCommon(_masterCopy).initialize
            (
                address(0), // Owner address
                address(0), // Linkdrop master address
                masterCopyVersion,
                chainId,
                uint(0) // transfer pattern (mint tokens on claim or transfer pre-minted tokens) 
            ),
            "INITIALIZATION_FAILED"
        );

        bytes memory bytecode = abi.encodePacked
        (
            hex"363d3d373d3d3d363d73",
            _masterCopy,
            hex"5af43d82803e903d91602b57fd5bf3"
        );

        _bytecode = bytecode;

        emit SetMasterCopy(_masterCopy, masterCopyVersion);
        return true;
    }

    /**
    * @dev Function to fetch the master copy version installed (or to be installed) to proxy
    * @param _linkdropMaster Address of linkdrop master
    * @param _campaignId Campaign id
    * @return Master copy version
    */
    function getProxyMasterCopyVersion(address _linkdropMaster, uint _campaignId) external view returns (uint) {

        if (!isDeployed(_linkdropMaster, _campaignId)) {
            return masterCopyVersion;
        }
        else {
            address proxy = address(uint160(deployed[salt(_linkdropMaster, _campaignId)]));
            return ILinkdropCommon(proxy).getMasterCopyVersion();
        }
    }

    /**
     * @dev Function to hash `_linkdropMaster` and `_campaignId` params. Used as salt when deploying with create2
     * @param _linkdropMaster Address of linkdrop master
     * @param _campaignId Campaign id
     * @return Hash of passed arguments
     */
    function salt(address _linkdropMaster, uint _campaignId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_linkdropMaster, _campaignId));
    }
  }

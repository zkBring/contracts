// SPDX-License-Identifier: GPL-3.0AA
pragma solidity ^0.8.17;
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "../interfaces/IBringDropCommon.sol";

contract BringFactoryCommon is Ownable {

    // Current version of mastercopy contract
    uint public dropContractVersion;
    
    // Contract bytecode to be installed when deploying proxy
    bytes internal _bytecode;

    // Bootstrap initcode to fetch the actual contract bytecode. Used to generate repeatable contract addresses
    bytes internal _initcode;

    // Network id
    uint public chainId;

    // Maps hash(sender address, campaign id) to its corresponding proxy address
    mapping (bytes32 => address) public deployed;
        
    // Events
    event Deployed(address indexed owner, uint campaignId, address proxy, bytes32 salt);
    event SetMasterCopy(address masterCopy, uint version);

    
    /**
    * @dev Indicates whether a proxy contract for BringDrop master is deployed or not
    * @param _dropCreator Address of BringDrop master
    * @param _campaignId Campaign id
    * @return True if deployed
    */
    function isDeployed(address _dropCreator, uint _campaignId) public view returns (bool) {
        return (deployed[salt(_dropCreator, _campaignId)] != address(0));
    }

    /**
    * @dev Indicates whether a link is claimed or not
    * @param _dropCreator Account that created drop
    * @param _campaignId Campaign id
    * @param _linkId Address corresponding to link key
    * @return True if claimed
    */
    function isClaimedLink(address _dropCreator, uint _campaignId, address _linkId) public view returns (bool) {

        if (!isDeployed(_dropCreator, _campaignId)) {
            return false;
        }
        else {
            address proxy = address(uint160(deployed[salt(_dropCreator, _campaignId)]));
            return IBringDropCommon(proxy).isClaimedLink(_linkId);
        }
    }

    /**
    * @dev Function to deploy a proxy contract for msg.sender and add a new signing key
    * @param _campaignId Campaign id
    * @param _signer Address corresponding to signing key
    * @return proxy Proxy contract address
    */
    function createDrop(uint _campaignId, address _signer)
    public
    returns (address proxy)
    {
        proxy = _deployProxy(msg.sender, _campaignId);
        IBringDropCommon(proxy).addSigner(_signer);
    }

    /**
    * @dev Internal function to deploy a proxy contract for BringDrop master
    * @param _dropCreator Address of drop creator
    * @param _campaignId Campaign id
    * @return proxy Proxy contract address
    */
    function _deployProxy(address _dropCreator, uint _campaignId)
    internal
    returns (address proxy)
    {

        require(!isDeployed(_dropCreator, _campaignId), "BRINGDROP_PROXY_CONTRACT_ALREADY_DEPLOYED");
        require(_dropCreator != address(0), "INVALID_BRINGDROP_MASTER_ADDRESS");

        bytes32 _salt = salt(_dropCreator, _campaignId);
        bytes memory initcode = getInitcode();

        assembly {
            proxy := create2(0, add(initcode, 0x20), mload(initcode), _salt)
            if iszero(extcodesize(proxy)) { revert(0, 0) }
        }

        deployed[_salt] = proxy;

        // Initialize factory address, BringDrop master address master copy version in proxy contract
        require
        (
            IBringDropCommon(proxy).initialize
            (
                _dropCreator, // BringDrop master address
                dropContractVersion
            ),
            "INITIALIZATION_FAILED"
        );

        emit Deployed(_dropCreator, _campaignId, proxy, _salt);
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
    * @param _masterCopy Address of BringDrop mastercopy contract to calculate bytecode from
    * @return True if updated successfully
    */
    function setMasterCopy(address _masterCopy)
    public onlyOwner
    returns (bool)
    {
        require(_masterCopy != address(0), "INVALID_MASTER_COPY_ADDRESS");
        dropContractVersion = dropContractVersion + 1;

        require
        (
            IBringDropCommon(_masterCopy).initialize
            (
                address(0), // BringDrop master address
                dropContractVersion
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

        emit SetMasterCopy(_masterCopy, dropContractVersion);
        return true;
    }

    /**
    * @dev Function to fetch the master copy version installed (or to be installed) to proxy
    * @param _dropCreator Address of BringDrop master
    * @param _campaignId Campaign id
    * @return Master copy version
    */
    function getProxyMasterCopyVersion(address _dropCreator, uint _campaignId) external view returns (uint) {

        if (!isDeployed(_dropCreator, _campaignId)) {
            return dropContractVersion;
        }
        else {
            address proxy = address(uint160(deployed[salt(_dropCreator, _campaignId)]));
            return IBringDropCommon(proxy).getMasterCopyVersion();
        }
    }

    /**
     * @dev Function to hash `_dropCreator` and `_campaignId` params. Used as salt when deploying with create2
     * @param _dropCreator Address of BringDrop master
     * @param _campaignId Campaign id
     * @return Hash of passed arguments
     */
    function salt(address _dropCreator, uint _campaignId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_dropCreator, _campaignId));
    }
  }

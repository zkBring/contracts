// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/ILinkdropCommon.sol";
import "../storage/LinkdropStorage.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/ILinkdropFactory.sol";
import "../libs/TransferHelper.sol";

contract LinkdropCommon is ILinkdropCommon, LinkdropStorage {

    /**
    * @dev Function called only once to set factory, linkdrop master, contract version and chain id
    * @param _factory Factory address
    * @param _linkdropMaster Address corresponding to master key
    * @param _version Contract version
    * @param _chainId Network id
    * @param _claimPattern which pattern the campaign will use (mint on claim, transfer pre-minted tokens, etc)
    */
    function initialize
    (
        address _factory,
        address _linkdropMaster,
        uint _version,
        uint _chainId,
        uint _claimPattern
    )
    public
    override      
    returns (bool)
    {
        require(!initialized, "LINKDROP_PROXY_CONTRACT_ALREADY_INITIALIZED");
        require(_claimPattern == 0 || _claimPattern == 1, "UNKNOWN_TRANSFER_PATTERN");        
        factory = ILinkdropFactory(_factory);
        linkdropMaster = _linkdropMaster;
        isLinkdropSigner[linkdropMaster] = true;
        version = _version;
        chainId = _chainId;
        claimPattern = _claimPattern;
        initialized = true;
        return true;
    }

    modifier onlyLinkdropMaster() {
        require(msg.sender == linkdropMaster, "ONLY_LINKDROP_MASTER");
        _;
    }

    modifier onlyLinkdropMasterOrFactory() {
      require (msg.sender == linkdropMaster || msg.sender == address(factory), "ONLY_LINKDROP_MASTER_OR_FACTORY");
        _;
    }

    modifier onlyFactory() {
      require(msg.sender == address(factory), "ONLY_FACTORY");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "LINKDROP_PROXY_CONTRACT_PAUSED");
        _;
    }


    /**
    * @dev Get linkdrop master for this contract
    * @return linkdrop master address
    */
    function getLinkdropMaster() public override view returns (address) {
      return linkdropMaster;
    }

    /**
    * @dev Indicates whether a link is claimed or not
    * @param _linkId Address corresponding to link key
    * @return True if claimed
    */
    function isClaimedLink(address _linkId) public override view returns (bool) {
        return claimedTo[_linkId] != address(0);
    }

    /**
    * @dev Indicates whether a link is canceled or not
    * @param _linkId Address corresponding to link key
    * @return True if canceled
    */
    function isCanceledLink(address _linkId) public override view returns (bool) {
        return _canceled[_linkId];
    }

    /**
    * @dev Indicates whether a contract is paused or not
    * @return True if paused
    */
    function paused() public override view returns (bool) {
        return _paused;
    }

    /**
    * @dev Function to cancel a link, can only be called by linkdrop master
    * @param _linkId Address corresponding to link key
    * @return True if success
    */
    function cancel(address _linkId) external override onlyLinkdropMaster returns (bool) {
        require(!isClaimedLink(_linkId), "LINK_CLAIMED");
        _canceled[_linkId] = true;
        emit Canceled(_linkId);
        return true;
    }

    /**
    * @dev Function to withdraw eth to linkdrop master, can only be called by linkdrop master
    * @return True if success
    */
    function withdraw(address _token) external override onlyLinkdropMaster returns (bool) {
        IERC20 token = IERC20(_token);
        TransferHelper.safeTransfer(_token, msg.sender, token.balanceOf(address(this)));
        return true;
    }

    /**
    * @dev Function to pause contract, can only be called by linkdrop master
    * @return True if success
    */
    function pause() external override onlyLinkdropMaster whenNotPaused returns (bool) {
        _paused = true;
        emit Paused();
        return true;
    }


    /**
    * @dev Function to add new signing key, can only be called by linkdrop master or factory
    * @param _linkdropSigner Address corresponding to signing key
    * @return True if success
    */
    function addSigner(address _linkdropSigner) external override onlyLinkdropMasterOrFactory returns (bool) {
        require(_linkdropSigner != address(0), "INVALID_LINKDROP_SIGNER_ADDRESS");
        isLinkdropSigner[_linkdropSigner] = true;
        return true;
    }

    /**
    * @dev Function to remove signing key, can only be called by linkdrop master
    * @param _linkdropSigner Address corresponding to signing key
    * @return True if success
    */
    function removeSigner(address _linkdropSigner) external override onlyLinkdropMaster returns (bool) {
        require(_linkdropSigner != address(0), "INVALID_LINKDROP_SIGNER_ADDRESS");
        isLinkdropSigner[_linkdropSigner] = false;
        return true;
    }

    /**
    * @dev Function for other contracts to be able to fetch the mastercopy version
    * @return Master copy version
    */
    function getMasterCopyVersion() external override view returns (uint) {
        return version;
    }

    /**
    * @dev Function to verify linkdrop receiver's signature
    * @param _linkId Address corresponding to link key
    * @param _receiver Address of linkdrop receiver
    * @param _signature ECDSA signature of linkdrop receiver
    * @return True if signed with link key
    */
    function verifyReceiverSignature
    (
        address _linkId,
        address _receiver,
        bytes memory _signature
    )
    public view
    override       
    returns (bool)
    {
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_receiver)));
        address signer = ECDSA.recover(prefixedHash, _signature);
        return signer == _linkId;
    }    
}

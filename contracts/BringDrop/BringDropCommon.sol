// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/IBringDropCommon.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "../libs/TransferHelper.sol";

contract BringDropCommon is IBringDropCommon {

    // Address of contract deploying proxies
    address public factory;

    // Address corresponding to BringDrop master key
    address public dropCreator;

    // Version of mastercopy contract
    uint public version;

    // Network id
    uint public chainId;

    // Indicates whether an address corresponds to a signing key under drop creators control
    mapping (address => bool) public isDropSigner;

    // Indicates who the link is claimed to
    mapping (address => address) public claimedTo;

    // Indicates whether the link is canceled or not
    mapping (address => bool) internal _canceled;

    // Indicates whether the initializer function has been called or not
    bool public initialized;

    // Indicates whether the contract is paused or not
    bool internal _paused;
    
    // Events
    event Canceled(address linkId);
    event Claimed(address indexed linkId, address indexed token, uint tokenAmount, address receiver);
    event ClaimedERC721(address indexed linkId, address indexed nft, uint tokenId, address receiver);
    event ClaimedERC1155(address indexed linkId, address indexed nft, uint tokenId, uint tokenAmount, address receiver);    
    event Paused();
    event AddedSigningKey(address dropSigner);
    event RemovedSigningKey(address dropSigner);


    
    /**
    * @dev Function called only once to set factory, BringDrop master, contract version and chain id
    * @param _factory Factory address
    * @param _dropCreator Address corresponding to master key
    * @param _version Contract version
    */
    function initialize
    (
        address _factory,
        address _dropCreator,
        uint _version,
        uint /* _chainId */,
        uint /* _claimPattern */ 
    )
    public
    override      
    returns (bool)
    {
        require(!initialized, "BRINGDROP_PROXY_CONTRACT_ALREADY_INITIALIZED");
        factory = _factory;
        dropCreator = _dropCreator;
        isDropSigner[dropCreator] = true;
        version = _version;
        chainId = block.chainid;
        initialized = true;
        return true;
    }

    modifier onlyDropCreator() {
        require(msg.sender == dropCreator, "ONLY_BRINGDROP_MASTER");
        _;
    }

    modifier onlyDropCreatorOrFactory() {
      require (msg.sender == dropCreator || msg.sender == address(factory), "ONLY_BRINGDROP_MASTER_OR_FACTORY");
        _;
    }

    modifier onlyFactory() {
      require(msg.sender == address(factory), "ONLY_FACTORY");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "BRINGDROP_PROXY_CONTRACT_PAUSED");
        _;
    }

    /**
    * @dev Get BringDrop master for this contract
    * @return BringDrop master address
    */
    function getDropCreator() public override view returns (address) {
      return dropCreator;
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
    * @dev Function to cancel a link, can only be called by BringDrop master
    * @param _linkId Address corresponding to link key
    * @return True if success
    */
    function cancel(address _linkId) external override onlyDropCreator returns (bool) {
        require(!isClaimedLink(_linkId), "LINK_CLAIMED");
        _canceled[_linkId] = true;
        emit Canceled(_linkId);
        return true;
    }

    /**
    * @dev Function to withdraw eth to BringDrop master, can only be called by BringDrop master
    * @return True if success
    */
    function withdraw(address _token) external override onlyDropCreator returns (bool) {
        IERC20 token = IERC20(_token);
        TransferHelper.safeTransfer(_token, msg.sender, token.balanceOf(address(this)));
        return true;
    }

    /**
    * @dev Function to pause contract, can only be called by BringDrop master
    * @return True if success
    */
    function pause() external override onlyDropCreator whenNotPaused returns (bool) {
        _paused = true;
        emit Paused();
        return true;
    }


    /**
    * @dev Function to add new signing key, can only be called by BringDrop master or factory
    * @param _dropSigner Address corresponding to signing key
    * @return True if success
    */
    function addSigner(address _dropSigner) external override onlyDropCreatorOrFactory returns (bool) {
        require(_dropSigner != address(0), "INVALID_BRINGDROP_SIGNER_ADDRESS");
        isDropSigner[_dropSigner] = true;
        return true;
    }

    /**
    * @dev Function to remove signing key, can only be called by BringDrop master
    * @param _dropSigner Address corresponding to signing key
    * @return True if success
    */
    function removeSigner(address _dropSigner) external override onlyDropCreator returns (bool) {
        require(_dropSigner != address(0), "INVALID_BRINGDROP_SIGNER_ADDRESS");
        isDropSigner[_dropSigner] = false;
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
    * @dev Function to verify BringDrop receiver's signature
    * @param _linkId Address corresponding to link key
    * @param _receiver Address of BringDrop receiver
    * @param _signature ECDSA signature of BringDrop receiver
    * @return True if signed with link key
    */
    function verifyReceiverSignature
    (
        address _linkId,
        address _receiver,
        bytes memory _signature
    )
    public pure
    override       
    returns (bool)
    {
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_receiver)));
        address signer = ECDSA.recover(prefixedHash, _signature);
        return signer == _linkId;
    }    
}

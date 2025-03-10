// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/IBringDropCommon.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "../libs/TransferHelper.sol";

contract BringDropCommon is IBringDropCommon {

    // Address corresponding to BringDrop master key
    address public creator;

    // Version of mastercopy contract
    uint public version;

    // a signing key under drop creators control
    address public signer;

    // Indicates who the link is claimed to
    mapping (address => address) public claimedTo;

    // Indicates whether the initializer function has been called or not
    bool public initialized;

    // Indicates whether the contract is paused or not
    bool internal stopped;
    
    // Events
    event Claimed(address indexed linkId, address indexed token, uint amount, address receiver);
    event Stopped();
    
    /**
    * @dev Function called only once to set factory, BringDrop master, contract version and chain id
    * @param _creator drop creator
    * @param _signer signer that was used to sign links     
    * @param _version Contract version
    */
    function initialize
    (
        address _creator,
        address _signer,
        uint _version        
    )
    public
    override      
    returns (bool)
    {
        require(!initialized, "BRINGDROP_PROXY_CONTRACT_ALREADY_INITIALIZED");
        creator = _creator;
        signer = _signer;
        version = _version;
        initialized = true;
        return true;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "BRING_ONLY_CREATOR");
        _;
    }

    modifier notStopped() {
        require(!stopped, "BRING_DROP_CONTRACT_STOPPED");
        _;
    }

    /**
    * @dev Get BringDrop master for this contract
    * @return BringDrop master address
    */
    function getCreator() public override view returns (address) {
      return creator;
    }

    /**
    * @dev Indicates whether a link is claimed or not
    * @param _linkId Address corresponding to link key
    * @return True if claimed
    */
    function isClaimed(address _linkId) public override view returns (bool) {
        return claimedTo[_linkId] != address(0);
    }

    /**
    * @dev Function to withdraw tokens back do drop creator
    * @return True if success
    */    
    function withdraw(address _token) public onlyCreator returns (bool) {
        IERC20 token = IERC20(_token);
        TransferHelper.safeTransfer(_token, msg.sender, token.balanceOf(address(this)));
        return true;
    }

    function stop() external override onlyCreator returns (bool) {
        stopped = true;
        /* require(withdraw(_token), "BRING_TOKEN_CANT_BE_WITHDRAWN"); */
        emit Stopped();
        return true;
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
        address recovered = ECDSA.recover(prefixedHash, _signature);
        return recovered == _linkId;
    }    
}

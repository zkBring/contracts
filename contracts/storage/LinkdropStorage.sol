// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract BringDropStorage {

    // Address of contract deploying proxies
    address public factory;

    // Address corresponding to BringDrop master key
    address public BringDropMaster;

    // Version of mastercopy contract
    uint public version;

    // Network id
    uint public chainId;

    // Indicates whether an address corresponds to BringDrop signing key
    mapping (address => bool) public isBringDropSigner;

    // Indicates who the link is claimed to
    mapping (address => address) public claimedTo;

    // Indicates whether the link is canceled or not
    mapping (address => bool) internal _canceled;

    // Indicates whether the initializer function has been called or not
    bool public initialized;

    // Indicates whether the contract is paused or not
    bool internal _paused;

    // Indicates which pattern the campaign will use (mint on claim, transfer pre-minted tokens, etc)  
    uint public claimPattern;
    
    // Events
    event Canceled(address linkId);
    event Claimed(address indexed linkId, address indexed token, uint tokenAmount, address receiver);
    event ClaimedERC721(address indexed linkId, address indexed nft, uint tokenId, address receiver);
    event ClaimedERC1155(address indexed linkId, address indexed nft, uint tokenId, uint tokenAmount, address receiver);    
    event Paused();
    event Unpaused();
    event AddedSigningKey(address BringDropSigner);
    event RemovedSigningKey(address BringDropSigner);

}

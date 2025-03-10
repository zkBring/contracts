// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "../interfaces/IFeeManager.sol";

contract LinkdropFactoryStorage is Ownable {

    // Current version of mastercopy contract
    uint public masterCopyVersion;

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;


import "./LinkdropFactoryERC20.sol";

//import "./LinkdropFactoryERC1155.sol";

contract LinkdropFactory is LinkdropFactoryERC20
    
/*, LinkdropFactoryERC1155 */ {


  /**
   * @dev Constructor that sets bootstap initcode, factory owner, chainId and master copy
   * @param _masterCopy Linkdrop mastercopy contract address to calculate bytecode from
   */
    constructor(address payable _masterCopy) {
        _initcode = (hex"6352c7420d6000526103ff60206004601c335afa6040516060f3");
        chainId = block.chainid;
        setMasterCopy(_masterCopy);
    }
  
}

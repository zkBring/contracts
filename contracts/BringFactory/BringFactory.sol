// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;


import "./BringFactoryERC20.sol";

contract BringFactory is BringFactoryERC20
    
/*, BringDropFactoryERC1155 */ {


  /**
   * @dev Constructor that sets bootstap initcode, factory owner, chainId and master copy
   * @param _mastercopy BringDrop mastercopy contract address to proxy calls to
   */
    constructor(address _mastercopy) {
        _initcode = (hex"6352c7420d6000526103ff60206004601c335afa6040516060f3");
        chainId = block.chainid;
        setMasterCopy(_mastercopy);
    }
  
}

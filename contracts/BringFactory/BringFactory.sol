// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;


import "./BringFactoryERC20.sol";

contract BringFactory is BringFactoryERC20    

  /**
   * @dev Constructor that sets bootstap initcode, factory owner, chainId and master copy
   * @param _mastercopy BringDrop mastercopy contract address to proxy calls to
   */
    constructor(address _mastercopy, uint _fee) {
        setFee(_fee);
        setMasterCopy(_mastercopy);
    }
  
}

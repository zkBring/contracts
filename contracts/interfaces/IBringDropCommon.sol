// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IBringDropCommon {

    function initialize
    (
        address _creator,
        address _signer,        
        uint _version
    )
    external returns (bool);

    function isClaimed(address _linkId) external view returns (bool);
    function withdraw(address _token) external returns (bool);
    function stop() external returns (bool);
    function getCreator() external view returns (address);
    function verifyReceiverSignature( address _linkId,
                                      address _receiver,
                                      bytes calldata _signature
                                      )  external view returns (bool);
}

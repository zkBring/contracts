// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IBringDropCommon {

    function initialize
    (
        address _dropCreator,
        uint _version
    )
    external returns (bool);

    function isClaimedLink(address _linkId) external view returns (bool);
    function isCanceledLink(address _linkId) external view returns (bool);
    function paused() external view returns (bool);
    function cancel(address _linkId) external returns (bool);
    function withdraw(address _token) external returns (bool);
    function pause() external returns (bool);
    function addSigner(address _BringDropSigner) external returns (bool);
    function removeSigner(address _BringDropSigner) external returns (bool);
    function getDropCreator() external view returns (address);
    function getMasterCopyVersion() external view returns (uint);
    function verifyReceiverSignature( address _linkId,
                                      address _receiver,
                                      bytes calldata _signature
                                      )  external view returns (bool);
}

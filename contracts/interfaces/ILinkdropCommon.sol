// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface ILinkdropCommon {

    function initialize
    (
        address _owner,
        address _linkdropMaster,
        uint _version,
        uint _chainId,
        uint _claimPattern
    )
    external returns (bool);

    function isClaimedLink(address _linkId) external view returns (bool);
    function isCanceledLink(address _linkId) external view returns (bool);
    function paused() external view returns (bool);
    function cancel(address _linkId) external returns (bool);
    function withdraw(address _token) external returns (bool);
    function pause() external returns (bool);
    function addSigner(address _linkdropSigner) external returns (bool);
    function removeSigner(address _linkdropSigner) external returns (bool);
    function getLinkdropMaster() external view returns (address);
    function getMasterCopyVersion() external view returns (uint);
    function verifyReceiverSignature( address _linkId,
                                      address _receiver,
                                      bytes calldata _signature
                                      )  external view returns (bool);
}

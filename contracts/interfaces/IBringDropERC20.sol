// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IBringDropERC20 {

    function verifyDropSignerSignature
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        bytes calldata _signature
    )
    external view returns (bool);

    function checkClaimParams
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        bytes calldata _dropSignerSignature,
        address _receiver,
        bytes calldata _receiverSignature
    )
    external view returns (bool);

    function claim
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        bytes calldata _dropSignerSignature,
        address _receiver,
        bytes calldata _receiverSignature
    )
      external payable returns (bool);
}

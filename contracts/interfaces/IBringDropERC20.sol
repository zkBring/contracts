// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IBringDropERC20 {

    function verifySignerSignature
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
        bytes calldata _signerSig,
        address _receiver,
        bytes calldata _receiverSig
    )
    external view returns (bool);

    function claim
    (
        address _token,
        uint _amount,
        uint _expiration,
        address _linkId,
        bytes calldata _signerSig,
        address _receiver,
        bytes calldata _receiverSig
    )
      external returns (bool);
}

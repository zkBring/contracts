// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface ILinkdropERC721 {

    function verifyLinkdropSignerSignatureERC721
    (
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        bytes calldata _signature
    )
    external view returns (bool);

    function verifyReceiverSignatureERC721
    (
        address _linkId,
        address _receiver,
        bytes calldata _signature
    )
    external view returns (bool);

    function checkClaimParamsERC721
    (
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        bytes calldata _linkdropSignerSignature,
        address _receiver,
        bytes calldata _receiverSignature
    )
    external view returns (bool);

    function claimERC721
    (
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature
    )
      external
      payable
      returns (bool);

}

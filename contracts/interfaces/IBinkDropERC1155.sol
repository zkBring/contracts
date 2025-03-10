// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface ILinkdropERC1155 {

    function verifyLinkdropSignerSignatureERC1155
    (
        address _nftAddress,
        uint _tokenId,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        bytes calldata _signature
    )
    external view returns (bool);

    function checkClaimParamsERC1155
    (
        address _nftAddress,
        uint _tokenId,
        uint _tokenAmount,        
        uint _expiration,
        address _linkId,
        bytes calldata _linkdropSignerSignature,
        address _receiver,
        bytes calldata _receiverSignature
     )
    external view returns (bool);

    function claimERC1155
    (
        address _nftAddress,
        uint _tokenId,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature
    )
    external payable returns (bool);
}

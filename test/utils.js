const ethers = require('ethers');
const { solidityPackedKeccak256, keccak256 } = ethers;

function buildCreate2Address(creatorAddress, saltHex, byteCode) {
  const byteCodeHash = keccak256(byteCode);
  return `0x${keccak256(
      `0x${['ff', creatorAddress, saltHex, byteCodeHash]
        .map(x => x.replace(/^0x/, ''))
        .join('')}`
    )
    .slice(-40)}`.toLowerCase();
}

const computeBytecode = masterCopyAddress => {
  const bytecode = `0x363d3d373d3d3d363d73${masterCopyAddress.slice(
    2
  )}5af43d82803e903d91602b57fd5bf3`;
  return bytecode;
};

const computeProxyAddress = (
  factoryAddress,
  linkdropMasterAddress,
  campaignId,
  initcode
) => {
  const salt = solidityPackedKeccak256(
    ['address', 'uint256'],
    [linkdropMasterAddress, campaignId]
  );
  const proxyAddress = buildCreate2Address(factoryAddress, salt, initcode);
  return proxyAddress;
};

// const signLink = async (
//   linkdropSigner, // Wallet instance
//   ethAmount,
//   tokenAddress,
//   tokenAmount,
//   expirationTime,
//   version,
//   chainId,
//   linkId,
//   proxyAddress
// ) => {
//   const messageHash = utils.solidityKeccak256(
//     ['uint256', 'address', 'uint256', 'uint256', 'uint256', 'uint256', 'address', 'address'],
//     [
//       ethAmount,
//       tokenAddress,
//       tokenAmount,
//       expirationTime,
//       version,
//       chainId,
//       linkId,
//       proxyAddress
//     ]
//   );
//   const messageHashToSign = utils.arrayify(messageHash);
//   const signature = await linkdropSigner.signMessage(messageHashToSign);
//   return signature;
// };

// const createLink = async (
//   linkdropSigner, // Wallet instance
//   ethAmount,
//   tokenAddress,
//   tokenAmount,
//   expirationTime,
//   version,
//   chainId,
//   proxyAddress
// ) => {
//   const linkWallet = ethers.Wallet.createRandom();
//   const linkKey = linkWallet.privateKey;
//   const linkId = linkWallet.address;
//   const linkdropSignerSignature = await signLink(
//     linkdropSigner,
//     ethAmount,
//     tokenAddress,
//     tokenAmount,
//     expirationTime,
//     version,
//     chainId,
//     linkId,
//     proxyAddress
//   );
//   return {
//     linkKey, // link's ephemeral private key
//     linkId, // address corresponding to the link key
//     linkdropSignerSignature // signature by linkdrop signer
//   };
// };

// const signReceiverAddress = async (linkKey, receiverAddress) => {
//   const wallet = new ethers.Wallet(linkKey);
//   const messageHash = utils.solidityKeccak256(['address'], [receiverAddress]);
//   const messageHashToSign = utils.arrayify(messageHash);
//   const signature = await wallet.signMessage(messageHashToSign);
//   return signature;
// };

module.exports = {
  buildCreate2Address,
  computeBytecode,
  computeProxyAddress,
  // signLink,
  // createLink,
  // signReceiverAddress
};

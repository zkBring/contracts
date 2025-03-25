const { ethers } = require("hardhat");

const generateEphemeralKeySig = async (ephemeralKey, recipient) => {
  const wallet = new ethers.Wallet(ephemeralKey)
  const abiCoder = new ethers.AbiCoder();  
  const encodedParams = abiCoder.encode(
    ['address'],
    [recipient]    
  );
  const dataHash = ethers.keccak256(encodedParams);
  const messageHash = ethers.hashMessage(ethers.getBytes(dataHash));
  
  const splitSig = wallet.signingKey.sign(messageHash);
  const signature = ethers.Signature.from(splitSig).serialized  
  // const recovered = ethers.recoverAddress(messageHash, signature);
  return signature
}

const xorAddresses = (address1, address2) => {
  // Remove the "0x" prefix if it exists
  const addr1 = address1.startsWith("0x") ? address1.slice(2) : address1;
  const addr2 = address2.startsWith("0x") ? address2.slice(2) : address2;
  
  if (addr1.length !== 40 || addr2.length !== 40) {
    throw new Error("Invalid address length");
  }

  // Convert the hex strings to BigInts and perform XOR
  const resultBigInt = BigInt("0x" + addr1) ^ BigInt("0x" + addr2);

  // Convert back to hex, pad to 40 hex characters, and add "0x" prefix
  let resultHex = resultBigInt.toString(16);
  resultHex = resultHex.padStart(40, "0");
  
  return "0x" + resultHex;
}

// const verifyAllocatorSig = async (taskId, schemaId, validator, signature) => {
//   // // Encode parameters as bytes
//   const abiCoder = new ethers.AbiCoder();  
//   const encodedParams = abiCoder.encode(
//   ["bytes32", "bytes32", "address"],
//     [taskId, schemaId, validator]
//   );
  
//   // Hash the encoded parameters using keccak256
//   const dataHash = ethers.keccak256(encodedParams);
//   const messageHash = ethers.hashMessage(ethers.getBytes(dataHash));
//   const recovered = ethers.recoverAddress(messageHash, signature);
//   return { signature, recovered }
// }
module.exports = {
  xorAddresses,
  generateEphemeralKeySig
}

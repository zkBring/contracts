const { ethers } = require("hardhat");
const { hexlify, toUtf8Bytes } = require('ethers')

const VALIDATOR_KEY = "e8efea4c3d300657768045af16852c5baa6e36b2c8c5faa419d363397bb21d7b";
const ALLOCATOR_KEY = "6000669c38cbebaa6849458e8179d76bfc2b8dcccabb390a98bc15860526a2e0";
const validator = new ethers.Wallet(VALIDATOR_KEY)
const allocator = new ethers.Wallet(ALLOCATOR_KEY)

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


const generateAllocatorSig = (taskId, schemaId, validatorAddress) => {
  const taskIdHex = hexlify(toUtf8Bytes(taskId));  
  const schemaIdHex = hexlify(toUtf8Bytes(schemaId));
  
  const abiCoder = new ethers.AbiCoder();  
  const encodedParams = abiCoder.encode(
    ["bytes32", "bytes32", "address"],
    [taskIdHex, schemaIdHex, validatorAddress]
  );
  const dataHash = ethers.keccak256(encodedParams);
  const messageHash = ethers.hashMessage(ethers.getBytes(dataHash));
  
  const splitSig = allocator.signingKey.sign(messageHash);
  const signature = ethers.Signature.from(splitSig).serialized  
  const recovered = ethers.recoverAddress(messageHash, signature);
  return {
    allocatorAddress: recovered,
    allocatorSignature: signature
  }
}

const generateValidatorSig = (taskId, schemaId, uHash, publicFieldsHash, recipient) => {
  const taskIdHex = hexlify(toUtf8Bytes(taskId));  
  const schemaIdHex = hexlify(toUtf8Bytes(schemaId));
  const abiCoder = new ethers.AbiCoder();  
  const encodedParams = abiCoder.encode(
    ["bytes32", "bytes32", "bytes32", "bytes32", "address"],
    [taskIdHex, schemaIdHex, uHash, publicFieldsHash, recipient]
  );
  const dataHash = ethers.keccak256(encodedParams);
  const messageHash = ethers.hashMessage(ethers.getBytes(dataHash));
  const splitSig = validator.signingKey.sign(messageHash);
  const signature = ethers.Signature.from(splitSig).serialized  
  const recovered = ethers.recoverAddress(messageHash, signature);
    return {
      validatorAddress: recovered,
      validatorSignature: signature
  }
}

const generateWebproof = (recipient, dropAddress) => {
  const taskId = "0cad2ec6ef3248a992d59e2315ce38d1"
  const schemaId = "c38b96722bd24b64b8d349ffd6391a8c"
  const publicFields = []
  const publicFieldsHash = "0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6"
  const uHash = "0xd4b1ee22a7a2eeb2adf53d79b7430a396ffcf699276112fa21949b8ff8fd172c"

  if (dropAddress) recipient = xorAddresses(dropAddress, recipient)
  
  const { validatorAddress, validatorSignature } = generateValidatorSig(taskId, schemaId, uHash, publicFieldsHash, recipient)  
  const { allocatorAddress, allocatorSignature } = generateAllocatorSig(taskId, schemaId, validatorAddress)
  
  const webproof = {
    taskId,
    publicFields,
    publicFieldsHash,
    uHash,
    allocatorAddress,
    allocatorSignature,
    validatorAddress,
    validatorSignature,
    recipient
  }
  return webproof
}

module.exports = {
  xorAddresses,
  generateEphemeralKeySig,
  generateWebproof
}

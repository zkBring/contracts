const { ethers } = require("hardhat");
const { hexlify, toUtf8Bytes } = require('ethers');

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
  return signature
}

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Claiming tokens with ephemeral key from: ", deployer.address);
  
  // Connect to the DropERC20 contract
  const dropAddress = "0x768424D027234812B2F11a74a7268c0b4A400083"; // Replace with your drop contract address
  const DropERC20 = await ethers.getContractFactory("DropERC20");
  const drop = DropERC20.attach(dropAddress);

  // Webproof data from tests
  const webproof = {
    "taskId": "0cad2ec6ef3248a992d59e2315ce38d1",
    "publicFields": [],
    "allocatorAddress": "0x19a567b3b212a5b35bA0E3B600FbEd5c2eE9083d",
    "publicFieldsHash": "0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6",
    "allocatorSignature": "0xe7694921b02ebd3c44a50ed83fda61bfe2de576c06096f121c2a3fb7c8b6000e793c1968d0e7dc417d68cebf95bc0a757f3371828085787d53bd1afd64a83d601b",
    "uHash": "0xd4b1ee22a7a2eeb2adf53d79b7430a396ffcf699276112fa21949b8ff8fd172c",
    "validatorAddress": "0xb1C4C1E1Cdd5Cf69E27A3A08C8f51145c2E12C6a",
    "validatorSignature": "0xcc97b2dc887e94013b7f4236b1412818065bf0ef94bbdb1b6b71a6b78d69d20852c834bbf3a123942a7386bac12ebd6da51a82217d269f9572aaa1422392ea111b",
    "recipient": "0xecdFC9CA344CE8E71538aFDf05c49E5Cbcd84b1a"
  }

  const ephemeralKey = "3f152b434d72ee6fdfebfae22b5e398b08ca51668c645a2903fa89b616230591"
  const ephemeralKeySig = await generateEphemeralKeySig(ephemeralKey, deployer.address);
  
  console.log("Claiming tokens...");
  
  // Call claimWithEphemeralKey function
  const tx = await drop.claimWithEphemeralKey(
    hexlify(toUtf8Bytes(webproof.taskId)),
    webproof.validatorAddress,
    webproof.uHash,
    webproof.publicFieldsHash,
    deployer.address, // recipient
    webproof.recipient, // ephemeral key address
    ephemeralKeySig,
    webproof.allocatorSignature,
    webproof.validatorSignature
  );
  
  console.log("Transaction sent:", tx.hash);
  await tx.wait();
  console.log("Tokens claimed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 

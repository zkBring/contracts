const { ethers } = require("hardhat");
const { hexlify, toUtf8Bytes } = require('ethers');

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Claiming tokens directly from: ", deployer.address);
  
  // Connect to the DropERC20 contract
  const dropAddress = "0xbc23e986704a429197fda71e8d5e3666c71ba8e9"; // Replace with your drop contract address
  const DropERC20 = await ethers.getContractFactory("DropERC20");
  const drop = DropERC20.attach(dropAddress);

  // Webproof data from tests
  const webproof = {
    "taskId": "c4ce77c1aebf4c2d91bc7bc3f341eeea",
    "publicFields": [],
    "allocatorAddress": "0x19a567b3b212a5b35bA0E3B600FbEd5c2eE9083d",
    "publicFieldsHash": "0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6",
    "allocatorSignature": "0x594c32220a846d52249007882a231944c182938e4fe329bfb4dc00ae4390880a78c6d5c79116a49764d92090c1d85d699f85220b1492a165d1fec24d6027e3b01b",
    "uHash": "0xd4b1ee22a7a2eeb2adf53d79b7430a396ffcf699276112fa21949b8ff8fd172c",
    "validatorAddress": "0xb1C4C1E1Cdd5Cf69E27A3A08C8f51145c2E12C6a",
    "validatorSignature": "0xf9d8c552e26c9eeb59410cb21b8c8f7dc4875ede62d0a618644255f39bfb2d0c16f926e975d3d69b4e4db957dbcd5d4b97f69cc1b8ec878fcb3e78d21226e3cb1c",
    "recipient": "0xC270728400F64f8DCD2030B589470e4C30F64bbd"
  }
  
  
  // Call claimWithEphemeralKey function
  const tx = await drop.claim(
    hexlify(toUtf8Bytes(webproof.taskId)),
    webproof.validatorAddress,
    webproof.uHash,
    webproof.publicFieldsHash,
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

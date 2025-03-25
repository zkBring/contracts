const { expect } = require("chai");
const { ethers } = require("hardhat");
const { hexlify, toUtf8Bytes } = require('ethers')


const EPHEMERAL_KEY = "3f152b434d72ee6fdfebfae22b5e398b08ca51668c645a2903fa89b616230591"

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


describe("DropERC20", function () {
  let DropERC20;
  let dropERC20;
  let MockERC20;
  let token;
  let owner;
  let user1;
  let user2;
  let user3;
  
  const amount = ethers.parseUnits("1000", 18);
  const claims = 5;
  const zkPassSchemaId = hexlify(toUtf8Bytes("c38b96722bd24b64b8d349ffd6391a8c"));
  const expiration = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
  const metadataIpfsHash = ethers.encodeBytes32String("metadata");

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    
    // Deploy mock ERC20 token
    MockERC20 = await ethers.getContractFactory("MockERC20");
    token = await MockERC20.deploy(ethers.parseUnits("1000000", 18));

    // Deploy DropERC20 contract
    DropERC20 = await ethers.getContractFactory("DropERC20");
    dropERC20 = await DropERC20.deploy(
      owner.address,
      token.target,
      amount,
      claims,
      zkPassSchemaId,
      expiration,
      metadataIpfsHash      
    );
    
    // Transfer tokens to the drop contract
    await token.transfer(dropERC20.target, amount * BigInt(claims));
  });

  describe("claim direclty", function () {
    // Test 1: Successful claim
    it("should allow a valid user to claim tokens", async function () {
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

      const ephemeralWallet = new ethers.Wallet(EPHEMERAL_KEY, ethers.provider);
      expect(ephemeralWallet.address).to.eq(webproof.recipient);

    const [deployer] = await ethers.getSigners();
    const fundingTx = await deployer.sendTransaction({
      to: ephemeralWallet.address,
      value: ethers.parseUnits("1", 18), // Sending 1 ETH (adjust as needed)
    });
    await fundingTx.wait();
      
      // Call claim function
      await dropERC20.connect(ephemeralWallet).claim(
        hexlify(toUtf8Bytes(webproof.taskId)),
        webproof.validatorAddress,
        webproof.uHash,
        webproof.publicFieldsHash,
        webproof.allocatorSignature,
        webproof.validatorSignature
      );
      
      const balanceAfter = await token.balanceOf(webproof.recipient);
      expect(balanceAfter).to.equal(amount);
    });

    // Test 2: Successful claim with ephemeral key
    it("should allow a valid user to claim tokens with ephemeral key", async function () {
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

      // this is a test key, do not import it and do not use it
      const ephemeralKey = EPHEMERAL_KEY
      const ephemeralKeySig = await generateEphemeralKeySig(ephemeralKey, user1.address)

      const balanceBefore = await token.balanceOf(user1.address);            
      // Call claim function
      await dropERC20.connect(user1).claimWithEphemeralKey(
        hexlify(toUtf8Bytes(webproof.taskId)),
        webproof.validatorAddress,
        webproof.uHash,
        webproof.publicFieldsHash,
        user1.address,
        webproof.recipient,
        ephemeralKeySig,
        webproof.allocatorSignature,
        webproof.validatorSignature
      );
      
      const balanceAfter = await token.balanceOf(user1.address);
      expect(balanceAfter - balanceBefore).to.equal(amount);
    });

    
    // Test 2: Prevent double claims
    xit("should prevent a user from claiming twice", async function () {
      // First claim should succeed
      await dropERC20.connect(user1).claim(/* zkProof parameters */);
      
      // Second claim should fail
      await expect(
        dropERC20.connect(user1).claim(/* zkProof parameters */)
      ).to.be.revertedWith("Already claimed");
    });

    // Test 3: Expiration check
    xit("should not allow claims after expiration", async function () {
      // Fast forward time to after expiration
      await ethers.provider.send("evm_increaseTime", [86401]); // 1 day + 1 second
      await ethers.provider.send("evm_mine");
      
      await expect(
        dropERC20.connect(user1).claim(/* zkProof parameters */)
      ).to.be.revertedWith("Drop expired");
    });

    // Test 4: Maximum claims check
    xit("should not allow more claims than the maximum", async function () {
      // Make all available claims
      for (let i = 0; i < claims; i++) {
        const user = await ethers.getSigner(i);
        await dropERC20.connect(user).claim(/* zkProof parameters */);
      }
      
      // The next claim should fail
      await expect(
        dropERC20.connect(user3).claim(/* zkProof parameters */)
      ).to.be.revertedWith("Maximum claims reached");
    });

    // Test 5: Invalid ZKPass proof check
    xit("should reject invalid ZKPass proofs", async function () {
      // Mock an invalid ZKPass verification
      
      await expect(
        dropERC20.connect(user1).claim(/* invalid zkProof parameters */)
      ).to.be.revertedWith("Invalid ZKPass proof");
    });

    // Test 6: Check claim event emission
    xit("should emit a Claimed event when tokens are claimed", async function () {
      await expect(dropERC20.connect(user1).claim(/* zkProof parameters */))
        .to.emit(dropERC20, "Claimed")
        .withArgs(user1.address, amount);
    });
  });
});

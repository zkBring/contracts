const { expect } = require("chai");
const { ethers } = require("hardhat");
const { hexlify, toUtf8Bytes } = require('ethers')

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

  describe("claim", function () {
    // Test 1: Successful claim
    it("should allow a valid user to claim tokens", async function () {
      // Mock ZKPass verification if needed
      // This will depend on your implementation

      const webproof = {
        "taskId":"e0a1b0da29554ed6823e5ae481d3e36a",
        "publicFields":[],
        "allocatorAddress":"0x19a567b3b212a5b35bA0E3B600FbEd5c2eE9083d",
        "publicFieldsHash":"0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6",        "allocatorSignature":"0x1adf885be2c9786a1875e29cb83baf6ce9d416ab19b08c55478514d45f5583463fcdbbcccfa4e0674210eadfdf0c45d81170ed137fee3a377c931523cb2692dc1c",
        "uHash":"0xd4b1ee22a7a2eeb2adf53d79b7430a396ffcf699276112fa21949b8ff8fd172c",
        "validatorAddress":"0xb1C4C1E1Cdd5Cf69E27A3A08C8f51145c2E12C6a",       "validatorSignature":"0xd517d0d3f4a10cfa6d83505c683407a675b957ed4ef8df5b218d2cbee549181267fdfb92630906650f602d2257ecf3997455bcd13502977976e7ea2155af9d541b"
      }
      
      const balanceBefore = await token.balanceOf(user1.address);
      // Call claim function
      await dropERC20.connect(user1).claim(
        hexlify(toUtf8Bytes(webproof.taskId)),
        webproof.validatorAddress,
        webproof.uHash,
        webproof.publicFieldsHash,
        user1.address,
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

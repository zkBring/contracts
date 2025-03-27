const { expect } = require("chai");
const { ethers } = require("hardhat");
const { hexlify, toUtf8Bytes } = require('ethers')
const { generateEphemeralKeySig,
        xorAddresses,
        generateWebproof
      } = require("./utils")

const EPHEMERAL_KEY = "3f152b434d72ee6fdfebfae22b5e398b08ca51668c645a2903fa89b616230591";
//const ZK_PASS_ALLOCATOR_ADDRESS = "0x19a567b3b212a5b35bA0E3B600FbEd5c2eE9083d";
const ZK_PASS_ALLOCATOR_ADDRESS = "0x304C45EBD6F80e0E055eaA115734105A31E48907";

describe("DropERC20", function () {
  let DropERC20;
  let dropERC20;
  let MockERC20;
  let bringToken;
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
    token = await MockERC20.deploy(ethers.parseUnits("1000000", 18), "Mock Token", "MOCK");

    // Deploy the Bring token
    bringToken = await MockERC20.deploy(ethers.parseUnits("1000000", 18), "Bring Token", "BRING"); // Mint 1000 tokens

    
    // Deploy DropERC20 contract
    DropERC20 = await ethers.getContractFactory("DropERC20");
    dropERC20 = await DropERC20.deploy(
      owner.address,
      token.target,
      amount,
      claims,
      zkPassSchemaId,
      expiration,
      metadataIpfsHash,
      ZK_PASS_ALLOCATOR_ADDRESS,
      bringToken.target
    );
    
    // Transfer tokens to the drop contract
    await token.transfer(dropERC20.target, amount * BigInt(claims));
  });

  describe("Storing data", function () {
    it("should store correct data", async function() {
      expect(await dropERC20.owner()).to.equal(owner.address)
      expect(await dropERC20.amount()).to.equal(amount)
      expect(await dropERC20.token()).to.equal(token)
      expect(await dropERC20.metadataIpfsHash()).to.equal(metadataIpfsHash)
      expect(await dropERC20.expiration()).to.equal(expiration)
      expect(await dropERC20.zkPassSchemaId()).to.equal(zkPassSchemaId)                              
    })
  })
  
  describe("Update Metadata", function() {
    it("should allow the owner to update the metadataIpfsHash", async function () {
      const newMetadataIpfsHash = "QmNewMetadataHash"; // example new IPFS hash
      await expect(dropERC20.updateMetadata(newMetadataIpfsHash))
          .to.emit(dropERC20, "MetadataUpdated")
          .withArgs(newMetadataIpfsHash);
      expect(await dropERC20.metadataIpfsHash()).to.equal(newMetadataIpfsHash);
    });

    it("should revert when a non-owner tries to update the metadataIpfsHash", async function () {
      const newMetadataIpfsHash = "QmAnotherMetadataHash";
      await expect(
        dropERC20.connect(user1).updateMetadata(newMetadataIpfsHash)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
  
  describe("claim direclty", function () {
    // Test 1: Successful claim
    it("should allow a valid user to claim tokens", async function () {
      const webproof = generateWebproof(user1.address)      

      expect(await dropERC20.hasUserClaimed(webproof.uHash)).to.equal(false);
      expect(await dropERC20.hasAddressClaimed(user1.address)).to.equal(false);
      
      // Call claim function
      await dropERC20.connect(user1).claim(
        hexlify(toUtf8Bytes(webproof.taskId)),
        webproof.validatorAddress,
        webproof.uHash,
        webproof.publicFieldsHash,
        webproof.allocatorSignature,
        webproof.validatorSignature
      );
      
      const balanceAfter = await token.balanceOf(webproof.recipient);
      expect(balanceAfter).to.equal(amount);
      expect(await dropERC20.hasUserClaimed(webproof.uHash)).to.equal(true);
      expect(await dropERC20.hasAddressClaimed(user1.address)).to.equal(true);      
    });

    
    // Test 2: Successful claim with ephemeral key
    it("should allow a valid user to claim tokens with ephemeral key", async function () {
      const ephemeralKeyAddress = "0xecdFC9CA344CE8E71538aFDf05c49E5Cbcd84b1a"
      const webproof = generateWebproof(ephemeralKeyAddress, dropERC20.target)

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
        ephemeralKeyAddress,
        ephemeralKeySig,
        webproof.allocatorSignature,
        webproof.validatorSignature
      );
      
      const balanceAfter = await token.balanceOf(user1.address);
      expect(balanceAfter - balanceBefore).to.equal(amount);
    });

    
    it("should corerctly compute webproof recipient for ephemeral key", async function () {
      const ephemeralKeyAddress = "0xecdFC9CA344CE8E71538aFDf05c49E5Cbcd84b1a"
      const computedWpRecipient = xorAddresses(dropERC20.target, ephemeralKeyAddress).toLowerCase()
      const wpRecipient = (await dropERC20.computeWpRecipientForEphemeralKey(ephemeralKeyAddress)).toLowerCase()
    })    
    
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

  describe("Stop function", function () {
    it("should allow the owner to stop the drop and transfer remaining tokens to owner", async function () {
      // Get owner's token balance before stopping.
      const ownerBalanceBefore = await token.balanceOf(owner.address);
      // Calculate the total tokens held by the drop contract.
      const contractBalance = await token.balanceOf(dropERC20.target);
      
      // Call stop as the owner and check that the Stopped event is emitted.
      await expect(dropERC20.stop())
        .to.emit(dropERC20, "Stopped");

      // Verify that the drop is marked as stopped.
      expect(await dropERC20.stopped()).to.equal(true);

      // Ensure the drop contract's balance is now zero.
      expect(await token.balanceOf(dropERC20.target)).to.equal(0);

      // Verify that the owner's balance has increased by the contract's previous balance.
      const ownerBalanceAfter = await token.balanceOf(owner.address);
      expect(ownerBalanceAfter - ownerBalanceBefore).to.equal(contractBalance);
    });

    it("should not allow non-owners to call stop", async function () {
      await expect(
        dropERC20.connect(user1).stop()
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should revert when stop is called twice", async function () {
      // Call stop the first time.
      await dropERC20.stop();

      // Call stop a second time; should revert because the campaign is already stopped.
      await expect(dropERC20.stop())
        .to.be.revertedWith("Campaign stopped");
    });

    it("should prevent claims after stop is called", async function () {
      // First, stop the drop campaign.
      await dropERC20.stop();

      // Generate a dummy webproof for testing purposes.
      const webproof = generateWebproof("0xecdFC9CA344CE8E71538aFDf05c49E5Cbcd84b1a");

      // Attempt to claim tokens after the drop has been stopped.
      await expect(
        dropERC20.connect(user1).claim(
          hexlify(toUtf8Bytes(webproof.taskId)),
          webproof.validatorAddress,
          webproof.uHash,
          webproof.publicFieldsHash,
          webproof.allocatorSignature,
          webproof.validatorSignature
        )
      ).to.be.revertedWith("Campaign stopped");
    });
  });

  describe("Staking functionality", function () {
    
    const stakeAmount1 = ethers.parseUnits("1000", 18);
    const stakeAmount2 = ethers.parseUnits("500", 18);
    
    beforeEach(async function () {
      // // Deploy a mock bring token
      // const MockERC20 = await ethers.getContractFactory("MockERC20");
      
      // re-deploy DropERC20 with the bring token address
      DropERC20 = await ethers.getContractFactory("DropERC20");
      dropERC20 = await DropERC20.deploy(
        owner.address,
        token.target,
        amount,
        claims,
        zkPassSchemaId,
        expiration,
        metadataIpfsHash,
        ZK_PASS_ALLOCATOR_ADDRESS,
        bringToken.target  // new bring token address
      );
    
      // Transfer drop tokens to the drop contract
      await token.transfer(dropERC20.target, amount * BigInt(claims));
    });

    it("should allow the owner to stake bring tokens", async function () {
      // Approve the drop contract to spend bring tokens from the owner
      await bringToken.connect(owner).approve(dropERC20.target, stakeAmount1);
      await expect(dropERC20.stake(stakeAmount1)).to.not.be.reverted;
      
      // Verify that the contract state updates
      expect(await dropERC20.bringStaked()).to.equal(stakeAmount1);
      expect(await bringToken.balanceOf(dropERC20.target)).to.equal(stakeAmount1);
    });

    it("should allow the owner to stake additional bring tokens", async function () {
      const totalStake = stakeAmount1 + stakeAmount2;
      await bringToken.connect(owner).approve(dropERC20.target, totalStake);
      
      await dropERC20.stake(stakeAmount1);
      expect(await dropERC20.bringStaked()).to.equal(stakeAmount1);
      
      await dropERC20.stake(stakeAmount2);
      expect(await dropERC20.bringStaked()).to.equal(totalStake);
      expect(await bringToken.balanceOf(dropERC20.target)).to.equal(totalStake);
    });
    
    it("should revert when non-owner tries to stake bring tokens", async function () {
      await bringToken.connect(owner).approve(dropERC20.target, stakeAmount1);
      await expect(
        dropERC20.connect(user1).stake(stakeAmount1)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
    
    it("should revert if staking zero tokens", async function () {
      await expect(
        dropERC20.stake(0)
      ).to.be.revertedWith("Stake amount must be greater than zero");
    });

    it("should transfer staked bring tokens back to owner when stop is called", async function () {
      // Owner approves and stakes bring tokens.
      await bringToken.connect(owner).approve(dropERC20.target, stakeAmount1);
      await dropERC20.stake(stakeAmount1);
      
      const ownerBringBalanceBefore = await bringToken.balanceOf(owner.address);
      
      // Call stop to end the campaign.
      await dropERC20.stop();
      
      // Ensure staked tokens are reset.
      expect(await dropERC20.bringStaked()).to.equal(0);
      
      // Owner's balance should increase by the staked amount.
      const ownerBringBalanceAfter = await bringToken.balanceOf(owner.address);
      expect(ownerBringBalanceAfter - ownerBringBalanceBefore).to.equal(stakeAmount1);
    });
  });
})

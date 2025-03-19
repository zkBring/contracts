// test/DropFactory.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DropFactory", function () {
    let DropFactory, dropFactory, MockERC20, mockToken, owner, addr1, addr2;

    beforeEach(async function () {
      // Get the ContractFactory and Signers here.
      DropFactory = await ethers.getContractFactory("DropFactory");
      MockERC20 = await ethers.getContractFactory("MockERC20");
      [owner, addr1, addr2] = await ethers.getSigners();
      
        // Deploy the MockERC20 token
      mockToken = await MockERC20.connect(addr2).deploy(ethers.parseUnits("1000000", 18)); // Mint 1000 tokens

      // Deploy the DropFactory contract
      dropFactory = await DropFactory.deploy(100, addr1.address); // 1% fee
      
      // Approve the DropFactory to spend tokens on behalf of addr2
      await mockToken.connect(addr2).approve(dropFactory.target, ethers.parseUnits("100", 18)); // Approve 100 tokens
    });

    describe("Deployment", function () {
        it("Should set the right fee and fee recipient", async function () {
            expect(await dropFactory.fee()).to.equal(100);
            expect(await dropFactory.feeRecipient()).to.equal(addr1.address);
        });
    });

    describe("Creating Drops", function () {
        it("Should create a new drop and emit DropCreated event", async function () {
            const tokenAddress = mockToken.target; // Use the mock token address
            const amount = ethers.parseUnits("10", 18);
            const claims = 5;
            const metadataIpfsHash = ethers.encodeBytes32String("metadata");
            const zkPassSchemaId = ethers.encodeBytes32String("schemaId");
            const expiration = Math.floor(Date.now() / 1000) + 86400; // 1 day from now

            // Create the drop
          await expect(dropFactory.connect(addr2).createDrop(tokenAddress, amount, claims, zkPassSchemaId, expiration, metadataIpfsHash))
                .to.emit(dropFactory, "DropCreated");
        });

        it("Should revert if the token transfer fails", async function () {
            const tokenAddress = mockToken.target; // Use the mock token address
            const amount = ethers.parseUnits("1000", 18); // Exceeding the allowance
            const claims = 5;
            const metadataIpfsHash = ethers.encodeBytes32String("metadata");
            const zkPassSchemaId = ethers.encodeBytes32String("schemaId");
            const expiration = Math.floor(Date.now() / 1000) + 86400; // 1 day from now

          
            // Attempt to create a drop without sufficient token allowance
          await expect(dropFactory.connect(addr2).createDrop(tokenAddress, amount, claims, zkPassSchemaId, expiration, metadataIpfsHash))
                .to.be.reverted;
        });
    });

    describe("Fee Management", function () {
        it("Should update the fee correctly", async function () {
            await dropFactory.updateFee(200); // Update fee to 2%
            expect(await dropFactory.fee()).to.equal(200);
        });

        it("Should update the fee recipient correctly", async function () {
            await dropFactory.updateFeeRecipient(addr2.address);
            expect(await dropFactory.feeRecipient()).to.equal(addr2.address);
        });
    });
});

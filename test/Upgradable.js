/* Global describe, it */
const { expect } = require("chai");

const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { computeBytecode, computeProxyAddress } = require('./utils')
let bytecode

const initcode = '0x6352c7420d6000526103ff60206004601c335afa6040516060f3'
const campaignId = 0
const DEFAULT_TRANSFER_PATTERN = 0
const MINT_ON_CLAIM_PATTERN = 1

describe('Proxy upgradability tests', () => {
  async function deployMasterCopyFixture() {
    let [dropCreator, deployer, relayer, dropSigner] = await ethers.getSigners()
    const MasterCopy = await ethers.getContractFactory("BringDrop");
    const masterCopy = await MasterCopy.deploy();
    await masterCopy.waitForDeployment();
    return { masterCopy }
  }
  
  async function deployFactoryFixture() {
    let [dropCreator, deployer, relayer, dropSigner] = await ethers.getSigners()
    const MasterCopy = await ethers.getContractFactory("BringDrop");
    const masterCopy = await MasterCopy.deploy();
    await masterCopy.waitForDeployment();
    
    const Factory = await ethers.getContractFactory("BringFactory");
    const factory = await Factory.deploy(masterCopy.target);
    await factory.waitForDeployment()
    return { factory, masterCopy, dropCreator, dropSigner };
  }
  
  it('should deploy initial master copy of linkdrop implementation', async () => {
    const { masterCopy } = await loadFixture(deployMasterCopyFixture);
    expect(masterCopy.target).to.not.eq(ethers.ZeroAddress)

    let masterCopyOwner = await masterCopy.factory()
    expect(masterCopyOwner).to.eq(ethers.ZeroAddress)

    let masterCopyLinkdropMaster = await masterCopy.dropCreator()
    expect(masterCopyLinkdropMaster).to.eq(ethers.ZeroAddress)

    let masterCopyVersion = await masterCopy.version()
    expect(masterCopyVersion).to.eq(0)

    let masterCopyChainId = await masterCopy.chainId()
    expect(masterCopyChainId).to.eq(0)
  })

  it('should deploy factory', async () => {
    const { factory, masterCopy } = await loadFixture(deployFactoryFixture);
    
    expect(factory.address).to.not.eq(ethers.ZeroAddress)
    let factoryVersion = await factory.dropContractVersion()
    expect(factoryVersion).to.eq(1)

    let factoryChainId = await factory.chainId()
    expect(factoryChainId).to.not.eq(0)

    let masterCopyOwner = await masterCopy.factory()
    expect(masterCopyOwner).to.eq(ethers.ZeroAddress)

    let masterCopyLinkdropMaster = await masterCopy.dropCreator()
    expect(masterCopyLinkdropMaster).to.eq(ethers.ZeroAddress)

    let masterCopyVersion = await masterCopy.version()
    expect(masterCopyVersion).to.eq(factoryVersion)

    let masterCopyChainId = await masterCopy.chainId()
    expect(masterCopyChainId).to.eq(factoryChainId)
  })

  it('should deploy proxy and delegate to implementation', async () => {
    const { factory, masterCopy, dropCreator, dropSigner } = await loadFixture(deployFactoryFixture);
    // Compute next address with js function
    let expectedAddress = computeProxyAddress(
      factory.target,
      dropCreator.address,
      campaignId,
      initcode
    )

    await expect(
      factory.createDrop(campaignId, dropSigner.address, {
        gasLimit: 6000000
      })
    ).to.emit(factory, 'Deployed')

    proxy = new ethers.Contract(
      expectedAddress,
      masterCopy.interface.format('json'),
      dropCreator
    )

    let dropCreatorAddress = await proxy.dropCreator()
    expect(dropCreatorAddress).to.eq(dropCreator.address)

    let version = await proxy.version()
    expect(version).to.eq(1)

    let owner = await proxy.factory()
    expect(owner).to.eq(factory.target)
  })

  async function deployCombinedFixture() {
    // Deploy factory and its initial master copy
    let { factory, masterCopy, dropCreator, dropSigner } = await deployFactoryFixture();
    // Deploy a new master copy
    let { masterCopy: newMS } = await deployMasterCopyFixture();
    // Update the factory with the new master copy
    const tx = await factory.setMasterCopy(newMS.target);
    await tx.wait();
    return { factory, newMS, dropCreator, dropSigner };
  }

  
  it('should set mastercopy and update bytecode in factory', async () => {
    let { factory, newMS } = await loadFixture(deployCombinedFixture);
    const expectedBytecode = computeBytecode(newMS.target);
    const deployedBytecode = await factory.getBytecode();
    expect(deployedBytecode.toString().toLowerCase()).to.eq(expectedBytecode.toString().toLowerCase());
  })
})

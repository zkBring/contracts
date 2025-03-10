/* global describe, it */
const { expect } = require("chai");

const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
//const { computeBytecode, computeProxyAddress } = require('./utils')
let bytecode

const initcode = '0x6352c7420d6000526103ff60206004601c335afa6040516060f3'
const chainId = 4 // Rinkeby
const campaignId = 0
const DEFAULT_TRANSFER_PATTERN = 0
const MINT_ON_CLAIM_PATTERN = 1


describe('Proxy upgradability tests', () => {
  async function deployMasterCopyFixture() {
    let [linkdropMaster, deployer, relayer, linkdropSigner] = await ethers.getSigners()
    const MasterCopy = await ethers.getContractFactory("LinkdropMastercopy");
    const masterCopy = await MasterCopy.deploy();
    await masterCopy.waitForDeployment();
    return { masterCopy }
  }
  
  async function deployFactoryFixture() {
    let [linkdropMaster, deployer, relayer, linkdropSigner] = await ethers.getSigners()
    const MasterCopy = await ethers.getContractFactory("LinkdropMastercopy");
    const masterCopy = await MasterCopy.deploy();
    await masterCopy.waitForDeployment();
    
    const Factory = await ethers.getContractFactory("LinkdropFactory");
    const factory = await Factory.deploy(masterCopy.target, chainId);
    await factory.waitForDeployment()
    return { factory, masterCopy };
  }
 
  it('should deploy initial master copy of linkdrop implementation', async () => {
    const { masterCopy } = await loadFixture(deployMasterCopyFixture);
    expect(masterCopy.target).to.not.eq(ethers.ZeroAddress)

    let masterCopyOwner = await masterCopy.factory()
    expect(masterCopyOwner).to.eq(ethers.ZeroAddress)

    let masterCopyLinkdropMaster = await masterCopy.linkdropMaster()
    expect(masterCopyLinkdropMaster).to.eq(ethers.ZeroAddress)

    let masterCopyVersion = await masterCopy.version()
    expect(masterCopyVersion).to.eq(0)

    let masterCopyChainId = await masterCopy.chainId()
    expect(masterCopyChainId).to.eq(0)
  })

  it('should deploy factory', async () => {
    const { factory, masterCopy } = await loadFixture(deployFactoryFixture);
    
    expect(factory.address).to.not.eq(ethers.ZeroAddress)
    let factoryVersion = await factory.masterCopyVersion()
    expect(factoryVersion).to.eq(1)

    let factoryChainId = await factory.chainId()
    expect(factoryChainId).to.eq(chainId)

    let masterCopyOwner = await masterCopy.factory()
    expect(masterCopyOwner).to.eq(ethers.ZeroAddress)

    let masterCopyLinkdropMaster = await masterCopy.linkdropMaster()
    expect(masterCopyLinkdropMaster).to.eq(ethers.ZeroAddress)

    let masterCopyVersion = await masterCopy.version()
    expect(masterCopyVersion).to.eq(factoryVersion)

    let masterCopyChainId = await masterCopy.chainId()
    expect(masterCopyChainId).to.eq(factoryChainId)
  })

  // xit('should deploy proxy and delegate to implementation', async () => {
  //   // Compute next address with js function
  //   let expectedAddress = computeProxyAddress(
  //     factory.address,
  //     linkdropMaster.address,
  //     campaignId,
  //     initcode
  //   )

  //   factory = factory.connect(linkdropMaster)

  //   await expect(
  //     factory.deployProxyWithSigner(campaignId, linkdropSigner.address, DEFAULT_TRANSFER_PATTERN, {
  //       gasLimit: 6000000
  //     })
  //   ).to.emit(factory, 'Deployed')

  //   proxy = new ethers.Contract(
  //     expectedAddress,
  //     LinkdropMastercopy.abi,
  //     deployer
  //   )

  //   let linkdropMasterAddress = await proxy.linkdropMaster()
  //   expect(linkdropMasterAddress).to.eq(linkdropMaster.address)

  //   let version = await proxy.version()
  //   expect(version).to.eq(1)

  //   let owner = await proxy.factory()
  //   expect(owner).to.eq(factory.address)
  // })

  // xit('should deploy second version of mastercopy', async () => {
  //   let oldMasterCopyAddress = masterCopy.address
  //   masterCopy = await deployContract(deployer, LinkdropMastercopy, [], {
  //     gasLimit: 6000000
  //   })

  //   expect(masterCopy.address).to.not.eq(ethers.constants.ZeroAddress)
  //   expect(masterCopy.address).to.not.eq(oldMasterCopyAddress)
  // })

  // xit('should set mastercopy and update bytecode in factory', async () => {
  //   bytecode = computeBytecode(masterCopy.address)
  //   factory = factory.connect(deployer)
  //   await factory.setMasterCopy(masterCopy.address)
  //   let deployedBytecode = await factory.getBytecode()
  //   expect(deployedBytecode.toString().toLowerCase()).to.eq(
  //     bytecode.toString().toLowerCase()
  //   )
  // })
})

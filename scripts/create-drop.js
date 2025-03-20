async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Creating new Drop from: ", deployer.address);
  
  // Connect to the already deployed DropFactory
  const dropFactoryAddress = "0xe95265429848b48E7a45c0566A9C088B72ecd1EA";
  const DropFactory = await ethers.getContractFactory("DropFactory");
  const dropFactory = DropFactory.attach(dropFactoryAddress);

  const MockToken = await ethers.getContractFactory("MockERC20");
  const tokenAddress = "0xAEBd651C93Cd4EaE21DD2049204380075548aDd5"
  const token = MockToken.attach(tokenAddress)
  let maxAmount = ethers.parseUnits("100000", 18)

  console.log("approving token...")
  await token.connect(deployer).approve(dropFactoryAddress, maxAmount); // Approve 
  console.log("token approved.")
  const amount = ethers.parseUnits("1000", 18);
  const claims = 5;
  const metadataIpfsHash = ethers.encodeBytes32String("metadata");
  const zkPassSchemaId = ethers.encodeBytes32String("schemaId");
  const expiration = Math.floor(Date.now() / 1000) + 86400; // 1 day from now

  console.log("creating drop")
  const drop = await dropFactory.createDrop(tokenAddress, amount, claims, zkPassSchemaId, expiration, metadataIpfsHash);
  console.log("New Drop created: ", drop);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 

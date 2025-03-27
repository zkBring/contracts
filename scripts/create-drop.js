const { hexlify, toUtf8Bytes } = require("ethers")

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Creating new Drop from: ", deployer.address);
  
  // Connect to the already deployed DropFactory
  const dropFactoryAddress = "0x0EB580F0ad587d464f2BE3C27DE7d831fc2f56e6";
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
  const metadataIpfsHash = "bafkreicqtmmxcbjclaf35wsvrncf3nyhmu3m4i7e56hl6dpe5hyuapmlfy";
  const zkPassSchemaId = hexlify(toUtf8Bytes("c38b96722bd24b64b8d349ffd6391a8c"));
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

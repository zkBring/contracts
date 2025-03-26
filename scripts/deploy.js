
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying DropFactory with the account:", deployer.address);

  // Set the fee to 0.3% (0.3 * 100 = 30)
  const fee = 30; // Fee in basis points (1 basis point = 0.01%)

  // Deploy the DropFactory contract
  const DropFactory = await ethers.getContractFactory("DropFactory");
  const ZK_PASS_ALLOCATOR_ADDRESS = "0x19a567b3b212a5b35bA0E3B600FbEd5c2eE9083d"
  const BRING_TOKEN = "0xaebd651c93cd4eae21dd2049204380075548add5"
  const dropFactory = await DropFactory.deploy(
    fee,
    deployer.address,
    ZK_PASS_ALLOCATOR_ADDRESS,
    BRING_TOKEN
  );

  console.log("DropFactory deployed to:", dropFactory.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 


async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying Test Bring Token with the account:", deployer.address);  
  
  // Deploy the DropFactory contract
  const Token = await ethers.getContractFactory("MockERC20");
  const initialSupply = ethers.parseUnits("100000000000", 18)
  const token = await Token.deploy(initialSupply);
  
  console.log("Token deployed to:", token.target);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 


async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying DropFactory with the account:", deployer.address);

    // Set the fee to 0.3% (0.3 * 100 = 30)
    const fee = 30; // Fee in basis points (1 basis point = 0.01%)

    // Deploy the DropFactory contract
    const DropFactory = await ethers.getContractFactory("DropFactory");
    const dropFactory = await DropFactory.deploy(fee, deployer.address);

    console.log("DropFactory deployed to:", dropFactory.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 

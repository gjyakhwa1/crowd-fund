const hre = require("hardhat");

async function main() {
  const CrowdTank = await hre.ethers.getContractFactory("CrowdTank");
  const crowdTank = await CrowdTank.deploy();

  await crowdTank.deployed();

  console.log("CrowdTank deployed to:", crowdTank.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

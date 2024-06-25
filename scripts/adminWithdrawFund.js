const { ethers } = require("hardhat");

const contractAddress = "";
async function main() {
  const CrowdTank = await ethers.getContractFactory("CrowdTank");
  const crowdTank = await CrowdTank.attach(contractAddress);
  const projectId = 1;
  const txn = await crowdTank.adminWithdrawFunds(projectId);
  console.log("Txn Status",txn.hash)
  console.log("Transaction",txn)
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });

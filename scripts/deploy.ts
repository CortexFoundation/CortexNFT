import { ethers } from "hardhat";
import dotenv from 'dotenv';
dotenv.config();

async function main() {
    const IcarusArt = await ethers.getContractFactory("IcarusArt");
    const icarus = await IcarusArt.deploy(process.env.NFT_ADDRESS!);
    await icarus.deployed();
    console.log("icarus address: ", icarus.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
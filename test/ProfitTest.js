// const { expect } = require("chai");

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PickFi", function() {
    let owner;
    let account1;
    let account2;

    const ABI = [
        "function approve(address spender, uint value) external returns (bool)",
        "function balanceOf(address addr) external view returns(uint256)"
    ];


    before(async function () {
        [owner, account1, account2] = await ethers.getSigners();
        console.log("Owner: ", owner.address, "account1:", account1.address);
    });

    it("Router setup", async function() {
        const CA = await ethers.getContractFactory("CortexArtERC721");
        art = await CA.deploy("CA", "CA", 1);
        await art.deployed();

        console.log(await art.platformAddress);
        await art.whitelistUser(owner.address, true);
        console.log(await art.test());
        let tx = await art.mintArtwork("1");
        await tx.wait();
    })

    async function skipBlocks(_num) {
        for(let i = 0; i < _num; ++i) {
            await network.provider.send("evm_mine");
        }
    }
})


function BN(_num) {
    let res = BigInt(_num * 1e18);
    return res;
}
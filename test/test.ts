import {expect} from "chai";
import {ethers} from "hardhat";
import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";

describe("icarus", function () {
    async function deployContractFixture() {
        const CortexArtErc721 = await ethers.getContractFactory("CortexArtERC721");
        const erc721 = await CortexArtErc721.deploy("cortex", "cortex", 1);
        await erc721.deployed();
        console.log("nft mock address: ", erc721.address);

        const IcarusArt = await ethers.getContractFactory("IcarusArt");
        const icarus = await IcarusArt.deploy(erc721.address);
        await icarus.deployed();
        console.log("icarus address: ", icarus.address);

        const [platform, creator] = await ethers.getSigners();
        //create artwork
        await erc721.whitelistUser(creator.address, true);
        const erc721_creator = erc721.connect(creator);
        await erc721_creator["mintArtwork(string)"]("0x1234");
        return {erc721_creator, icarus};
    }

    describe("token sell", function () {
        it("fixed price token sale", async function () {
            const {erc721_creator, icarus} = await loadFixture(deployContractFixture);
            const [, creator, buyer1, buyer2] = await ethers.getSigners();
            let price = ethers.utils.parseEther("1");

            const icarus_c = icarus.connect(creator);
            await erc721_creator.setApprovalForAll(icarus.address, true);
            await icarus_c.setSellingState(1, price, 0, 0, 0);
            const creatorB = await creator.getBalance();
            const icarus_b1 = icarus.connect(buyer1);
            await icarus_b1.takeBuyPrice(1, {value: price});
            expect((await creator.getBalance()).sub(creatorB)).to.equals(price, "first sale, creator should get all ");

            console.log("first finish");
            price = ethers.utils.parseEther("2");
            const erc721_b1 = erc721_creator.connect(buyer1);
            const icarus_b2 = icarus.connect(buyer2);
            await erc721_b1.setApprovalForAll(icarus.address, true);
            await icarus_b1.setSellingState(1, price, 0, 0, 0);

            // before
            const balance_b1 = await buyer1.getBalance();
            const balance_creator = await creator.getBalance();

            await icarus_b2.takeBuyPrice(1, {value: price});

            expect((await buyer1.getBalance()).sub(balance_b1)).to.equals(price.mul(9).div(10));
            expect((await creator.getBalance()).sub(balance_creator)).to.equals(price.div(10));
        })
    })
});
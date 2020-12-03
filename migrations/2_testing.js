const Artwork = artifacts.require("Artwork");
const Controller = artifacts.require("CrossChainController");
const EthArtwork = artifacts.require("ERC721CrossChainArtwork");
const EthController = artifacts.require("ERC721CrossChainController");

module.exports = async function(deployer, network, accounts) {
    let owner = accounts[0];

    // await deployer.deploy(Controller);
    // let controller = await Controller.deployed();
    await deployer.deploy(Artwork, "Cross Chain Test", "CCT", "Demo");
    let artwork = await Artwork.deployed();

    let ctr = await deployer.deploy(Controller);
    let ethCtr = await deployer.deploy(EthController);
    console.log(await artwork.name(), await artwork.symbol(), await artwork.seriesName());
    await ethCtr.registerMinter(artwork.address, await artwork.name(), await artwork.symbol(), await artwork.seriesName());
    await ctr.registerLocker(artwork.address, await ethCtr.nftCrossChainMapping(artwork.address));

    await artwork.addItems(owner, "test", 5);
    await artwork.setApprovalForAll(ctr.address, true);
};

const Artwork = artifacts.require("Artwork");
const CrossChainController = artifacts.require("CrossChainController");

module.exports = async function(deployer, network, accounts) {
    let owner = accounts[0];

    // await deployer.deploy(CrossChainController);
    // let controller = await CrossChainController.deployed();
    await deployer.deploy(Artwork, "Cross Chain Test");
    let artwork = await Artwork.deployed();
    // // console.log(artwork);
    // for(let i = 0; i < 5; ++i) {
    //     let tokenURI = ("testing uri " + (i + 1));
    //     console.log(tokenURI);
    //     await artwork.addItem(owner, tokenURI);
    // }
    
    // await artwork.setApprovalForAll(controller.address, "true");
  
};

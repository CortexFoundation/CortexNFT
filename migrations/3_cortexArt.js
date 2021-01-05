const Art = artifacts.require("CortexArt");

module.exports = async function(deployer, network, accounts) {
    let owner = accounts[0];
    let artist = accounts[1];

    await deployer.deploy(Art, "Cortex Art", "CA", "1", {from: owner});
    let art = await Art.deployed();
    await art.whitelistTokenForCreator(artist, 1, 10, 30, {from: owner});
    await art.mintArtwork(1, "newToken", 0, [artist], {from: artist});
    let currentTime = Math.floor(Date.now() / 1000);
    console.log(currentTime);
    await art.openAuction(1, currentTime + 100, currentTime + 400, 0, {from: artist});
};

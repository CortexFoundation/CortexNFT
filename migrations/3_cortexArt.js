const Art = artifacts.require("CortexArt");

module.exports = async function(deployer, network, accounts) {
    let owner = accounts[0];

    await deployer.deploy(Art, "Cortex Art", "CA", "1");
    let art = await Art.deployed();
};

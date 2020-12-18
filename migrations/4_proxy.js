const Art = artifacts.require("CortexArt");
const Proxy = artifacts.require("UpgradeabilityProxy");

module.exports = async function(deployer, network, accounts) {
    let owner = accounts[0];

    let art = await Art.deployed();
    console.log(art.address);
    await deployer.deploy(Proxy, art.address, "0x");
};

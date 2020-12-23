const Art = artifacts.require("CortexArtUpgradeable");
const Proxy = artifacts.require("UpgradeabilityProxy");
const CRC = artifacts.require("CRC4FullUpgradeable");


module.exports = async function(deployer, network, accounts) {
    let owner = accounts[0];

    // await deployer.deploy(CRC);

    // return;
    await deployer.deploy(Art);
    // let art = await Art.deployed();
    // console.log(art.address);
    // await deployer.deploy(Proxy, art.address, "0x");
};

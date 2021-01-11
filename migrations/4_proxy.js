const Art = artifacts.require("CortexArtUpgradeable");
const Proxy = artifacts.require("AdminUpgradeabilityProxy");
const CRC = artifacts.require("CRC4FullUpgradeable");


module.exports = async function(deployer, network, accounts) {
    let owner = accounts[0];

    // await deployer.deploy(CRC);

    // return;
    // await deployer.deploy(Art);
    // let art = await Art.deployed();
    // console.log(art.address);
    await deployer.deploy(Proxy, "0x8458b580162Ce815B1b1dc655149aB83FD57FB2d", owner, "0x");
};

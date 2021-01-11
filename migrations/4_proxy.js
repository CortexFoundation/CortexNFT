const Art = artifacts.require("CortexArtUpgradeable");
const Proxy = artifacts.require("AdminUpgradeabilityProxy");
const CRC = artifacts.require("CRC4FullUpgradeable");


module.exports = async function(deployer, network, accounts) {
    let owner = accounts[0];

    // await deployer.deploy(CRC);

    // return;
    await deployer.deploy(Art);
    // let art = await Art.deployed();
    // console.log(art.address);
    // await deployer.deploy(Proxy, "0x14c30d15A3BF2Fd99ebe66B1C60674D9BBF89332", owner, "0x");
};

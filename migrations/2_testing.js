const Artwork = artifacts.require("Artwork");
const Controller = artifacts.require("CrossChainController");
const EthArtwork = artifacts.require("ERC721CrossChainArtwork");
const EthController = artifacts.require("ERC721CrossChainController");

module.exports = async function(deployer, network, accounts) {
    let owner = accounts[0];

    let artworks = [
        ["大型粒子对撞机和车厘子芭蕾TUTU裙", "https://ipfs.io/ipfs/QmVjCMvPRGqLwRdHp6G9eJHioNSQocwdQkhMRfMeV4JtdK"],
        ["幻想几何学1", "https://ipfs.io/ipfs/QmbLJJHKFNmvwFq475iYCCAw8vvBwhRqSqLgEVztmpUDAr"],
        ["幻想几何学2", "https://ipfs.io/ipfs/QmUGDLFTd9AUSJbGdMsTn9udT8qPJykng4ynMFGZrpL3bB"],
        ["升维", "https://ipfs.io/ipfs/QmWexPNLXEXpGPdNVGzu9LMLaQ5s8eaaDxySwbgEvkEpuS"],
        ["升维", "https://ipfs.io/ipfs/QmUgJprVj2JfJarz1pq1nGY49zvDJngHgUAqF8E3DeoqNw"],
        ["区块链上百老汇爵士乐", "https://ipfs.io/ipfs/QmdBjLM6VF7twBdxgRE12fQeZJi3R5Pc6aXPw8x2dFiG4A"],
        ["高棉的微笑", "https://ipfs.io/ipfs/QmXDDN3qaz36TQoSEmY1EKYDtroq6iugM8y6Njrn4cvd5h"]
    ];

    let contollerAddr = "0x4b3bd3f6234a67e83637d8c279307eb31b9d2c01";
    for(let i = 6; i < artworks.length; ++i) {
        console.log(artworks[i][0]);
        await deployer.deploy(Artwork, "Alice 1", "AI", artworks[i][0]);
        let artwork = await Artwork.deployed();
        await artwork.addItem(owner, artworks[i][1]);
        await artwork.setApprovalForAll(contollerAddr, true);
        // await ctr.registerLocker(artwork.address, await ethCtr.nftCrossChainMapping(artwork.address));
    }
    // await deployer.deploy(Artwork, "Cross Chain Test", "CCT", "Demo");
    // let artwork = await Artwork.deployed();

    // let ctr = await deployer.deploy(Controller);
    // let ethCtr = await deployer.deploy(EthController);
    // console.log(await artwork.name(), await artwork.symbol(), await artwork.seriesName());
    // await ethCtr.registerMinter(artwork.address, await artwork.name(), await artwork.symbol(), await artwork.seriesName());
    // await ctr.registerLocker(artwork.address, await ethCtr.nftCrossChainMapping(artwork.address));

    // await artwork.addItems(owner, "test", 5);
    // await artwork.setApprovalForAll(ctr.address, true);
};

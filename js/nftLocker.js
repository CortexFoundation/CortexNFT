const Web3 = require('web3');
const fs = require('fs');
const crossChainControllerArtifact = require('../build/contracts/CrossChainController.json');
const nftArtifact = require('../build/contracts/Artwork.json');

// const providerSource = new Web3.providers.HttpProvider('http://web3.cortexlabs.ai:30089');
// 主网内网节点：
// const providerSource = new Web3.providers.HttpProvider('http://storage.cortexlabs.ai:30089');
const providerSource = new Web3.providers.HttpProvider('HTTP://127.0.0.1:7545');
const web3Source = new Web3(providerSource);

const providerCrossChain = new Web3.providers.HttpProvider('https://mainnet.infura.io/v3/03fe211fc9a64c4ca614ca04e6d45c5d');
// const providerCrossChain = new Web3.providers.HttpProvider('TTP://127.0.0.1:7545');
const web3CrossChain = new Web3(providerCrossChain);


async function getCurrentBlockNum(_web3){
    try{
        return await _web3.eth.getBlockNumber();
    } 
    catch(e) {
        console.log("unable to get block number, retrying...")
        return await getCurrentBlockNum(_web3);
    }
}

async function getPastEvents(_eventName, _fromBlock){
    try{
        return await nftLockerContract.getPastEvents(_eventName, {fromBlock: _fromBlock});
    } 
    catch(e) {
        console.log("unable to get events, retrying...")
        return await getPastEvents(_eventName, _fromBlock);
    }
}

async function main() {
    console.log("Starting from block: " + blockCount);
    await new Promise(r => setTimeout(r, 1000));
    let pastEvents = await getPastEvents("Lock", blockCount);
    pastEvents.forEach(async (element) =>  {
        // listen for Lock event
        console.log(element.returnValues);
        let owner = element.returnValues["_from"];
        let sourceNftAddr = element.returnValues["_nftAddr"];
        let tokenId = element.returnValues["_tokenId"];
        let crossChainNftAddr = await nftLockerContract.methods
            .nftCrossChainMapping(sourceNftAddr)
            .call({from: "0x17eb9e0c2924338ffeed678e7db0363d9d5ba3bb", gas:1000000});
        var nftContract = new web3Source.eth.Contract(nftArtifact.abi, sourceNftAddr);
        let tokenURI = await nftContract.methods
            .tokenURI(tokenId)
            .call({from: "0x17eb9e0c2924338ffeed678e7db0363d9d5ba3bb", gas:1000000});
        console.log(tokenURI);

        // Mint

        mint(web3CrossChain, sourceNftAddr, owner, tokenId, tokenURI);
    });
    return;
    while(true) {
        let pastEvents = await getPastEvents("Lock", {fromBlock: blockCount});
        console.log(pastEvents);
        blockCount = await getCurrentBlockNum(web3Source);
        blockCountFile.write(blockCount);
        // wait for 60 seconds
        await new Promise(r => setTimeout(r, 60000));
    }
}

function initiateData(){
    let content = fs.readFileSync("./blockCount.txt", 'utf8');
    blockCount = parseInt(content);
    console.log(typeof(blockCount), blockCount);
}

var blockCount = 30;
var fromAddr = "0xC635adD7f26F53658e7C6DaDdE3673A1F597e364";
var privateKey = "1b61de2dddde7cad05e6fa4f14f544c6f728605c820b233a2a61d1df6f7faaf5";
var crossChainControllerAddr = "0xBfBA638c6371938816Dc6a44ba3C30c251D0dF77";
var nftLockerContract = new web3Source.eth.Contract(crossChainControllerArtifact.abi, crossChainControllerAddr);
// initiateData();
// var blockCountFile = fs.createWriteStream('blockCount.txt');

function mint(_web3, _sourceNftAddr, _owner, _tokenId, _tokenURI) {
    var mintAbi = nftLockerContract.methods.mint(_sourceNftAddr, _owner, _tokenId, _tokenURI);
    // var mintAbi = nftLockerContract.methods.mint("0xFbfbF8376db8b6aa81e4aB1a09054d33409cA570", "0xC635adD7f26F53658e7C6DaDdE3673A1F597e364", 2, "tokenURI from JS");
    var encodedABI = mintAbi.encodeABI();

    console.log(encodedABI);

    var tx = {
        from: fromAddr,
        to: crossChainControllerAddr,
        gas: 2000000,
        data: encodedABI
    }; 

    _web3.eth.accounts.signTransaction(tx, privateKey).then(signed => {
        var tran = _web3.eth.sendSignedTransaction(signed.rawTransaction);
        tran.on('transactionHash', hash => {
            console.log('hash');
            console.log(hash);
        });
        tran.on('error', console.error);
    });
}

main();



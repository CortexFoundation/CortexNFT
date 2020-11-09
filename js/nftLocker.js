const Web3 = require('web3');
const fs = require('fs');
const crossChainControllerArtifact = require('../build/contracts/CrossChainController.json');

const providerETH = new Web3.providers.HttpProvider('https://mainnet.infura.io/v3/03fe211fc9a64c4ca614ca04e6d45c5d');
const web3ETH = new Web3(providerETH);
// const providerCTXC = new Web3.providers.HttpProvider('http://web3.cortexlabs.ai:30089');
// 主网内网节点：
// const providerCTXC = new Web3.providers.HttpProvider('http://storage.cortexlabs.ai:30089');
const providerCTXC = new Web3.providers.HttpProvider('HTTP://127.0.0.1:7545');
const web3CTXC = new Web3(providerCTXC);


async function getCurrentBlockNum(){
    try{
        return await web3CTXC.eth.getBlockNumber();
    } 
    catch(e) {
        console.log("unable to get block number, retrying...")
        return await getCurrentBlockNum();
    }
}

async function getPastEvents(_eventName, _fromBlock){
    try{
        return await nftLockerContract.getPastEvents(_eventName, {fromBlock: _fromBlock});
    } 
    catch(e) {
        console.log("unable to get events, retrying...")
        return await getPastEvents();
    }
}

async function main() {
    console.log("Starting from block: " + blockCount);
    await new Promise(r => setTimeout(r, 1000));
    let pastEvents = await getPastEvents("Lock", {fromBlock: blockCount});
    console.log(pastEvents);
    return;
    while(true) {
        let pastEvents = await getPastEvents("Lock", {fromBlock: blockCount});
        console.log(pastEvents);
        blockCount = await getCurrentBlockNum();
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

var blockCount = 0;
var crossChainControllerAddr = "0xBfBA638c6371938816Dc6a44ba3C30c251D0dF77";
var nftLockerContract = new web3CTXC.eth.Contract(crossChainControllerArtifact.abi, crossChainControllerAddr);
// initiateData();
// var blockCountFile = fs.createWriteStream('blockCount.txt');

main()



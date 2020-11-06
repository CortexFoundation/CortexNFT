const Web3 = require('web3');
const fs = require('fs');
const nftLockerBuild = require('./build/contracts/NFTLocker.json');

const providerETH = new Web3.providers.HttpProvider('https://mainnet.infura.io/v3/03fe211fc9a64c4ca614ca04e6d45c5d');
const web3ETH = new Web3(providerETH);
// const provider = new Web3.providers.HttpProvider('http://web3.cortexlabs.ai:30089');
// 主网内网节点：
const providerCTXC = new Web3.providers.HttpProvider('http://storage.cortexlabs.ai:30089');
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
    await new Promise(r => setTimeout(r, 5000));
    while(true) {
        let pastEvents = await getPastEvents("lockNft", {fromBlock: blockCount});
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
var nftLockerContractAddr = "0xba19f0fb4472f4710d18b5cc189dbdb62dc7b220";
var nftLockerContract = new web3CTXC.eth.Contract(nftLockerBuild.abi, nftLockerContractAddr);
initiateData();
var blockCountFile = fs.createWriteStream('blockCount.txt');

main()



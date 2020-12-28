const Web3 = require('web3');
const fs = require('fs');
const crossChainControllerArtifact = require('../build/contracts/CrossChainController.json');
const nftArtifact = require('../build/contracts/Artwork.json');

var account = require("./account.json");

const providerSource = new Web3.providers.HttpProvider('http://web3.cortexlabs.ai:30089');
// const providerSource = new Web3.providers.HttpProvider('HTTP://127.0.0.1:7545');
const web3Source = new Web3(providerSource);

// const providerCrossChain = new Web3.providers.HttpProvider('https://mainnet.infura.io/v3/03fe211fc9a64c4ca614ca04e6d45c5d');
const providerCrossChain = new Web3.providers.HttpProvider('https://kovan.infura.io/v3/1fc42d30c8a24e0183003704523a43d8');
// const providerCrossChain = new Web3.providers.HttpProvider('http://127.0.0.1:7545');
const web3CrossChain = new Web3(providerCrossChain);

var blockCount = 2812917;
var fromAddr = account.address;
var privateKey = account.privateKey;
var crossChainControllerSourceAddr = "0x0f7457e3ca76c07ee4a69c03370308471905bb45";
// var crossChainControllerTargetAddr = "0x3E7814cb9793C7CB8CED25C054C1b6ABBE9b4Fa8";
// kovan:
var crossChainControllerTargetAddr = "0x05524cF790f7C18F583889422e55a1eB02686946";

// initiateData();
// var blockCountFile = fs.createWriteStream('blockCount.txt');
main();

function initiateData(){
    let content = fs.readFileSync("./blockCount.txt", 'utf8');
    blockCount = parseInt(content);
    console.log(typeof(blockCount), blockCount);
}

async function main() {
    console.log("Starting from block: " + blockCount);
    await new Promise(r => setTimeout(r, 1000));
    while(true) {
        let sourceControllerContract = new web3Source.eth.Contract(crossChainControllerArtifact.abi, crossChainControllerSourceAddr);
        let pastEvents = await getPastEvents(sourceControllerContract, "Lock", blockCount);
        pastEvents.forEach(async (element) =>  {
            // listen for Lock event
            console.log(element.returnValues);
            let owner = element.returnValues["_from"];
            let sourceNftAddr = element.returnValues["_nftAddr"];
            let tokenId = element.returnValues["_tokenId"];
            let crossChainNftAddr = await sourceControllerContract.methods
                .nftCrossChainMapping(sourceNftAddr)
                .call({from: "0x17eb9e0c2924338ffeed678e7db0363d9d5ba3bb", gas:1000000});
            var nftContract = new web3Source.eth.Contract(nftArtifact.abi, sourceNftAddr);
            let tokenURI = await nftContract.methods
                .tokenURI(tokenId)
                .call({from: "0x17eb9e0c2924338ffeed678e7db0363d9d5ba3bb", gas:1000000});
                
            // Mint
            console.log("Source nft: " + sourceNftAddr + ", owner: " + owner + ", tokenId: " + tokenId + ", tokenURI: " + tokenURI);
            mint(web3CrossChain, crossChainControllerTargetAddr, sourceNftAddr, owner, tokenId, tokenURI);
        });

        blockCount = await getCurrentBlockNum(web3Source);
        // blockCountFile.write(blockCount);
        // wait for 60 seconds
        await waitForSecond(60);
    }
}

function mint(_web3, _controllerAddr, _sourceNftAddr, _owner, _tokenId, _tokenURI) {
    let controllerContract = new web3Source.eth.Contract(crossChainControllerArtifact.abi, _controllerAddr);
    let mintAbi = controllerContract.methods.mint(_sourceNftAddr, _owner, _tokenId, _tokenURI);
    // var mintAbi = controllerContract.methods.mint("0xFbfbF8376db8b6aa81e4aB1a09054d33409cA570", "0xC635adD7f26F53658e7C6DaDdE3673A1F597e364", 2, "tokenURI from JS");
    let encodedABI = mintAbi.encodeABI();

    console.log(encodedABI);

    let tx = {
        from: fromAddr,
        to: _controllerAddr,
        gas: 2000000,
        data: encodedABI
    }; 

    _web3.eth.accounts.signTransaction(tx, privateKey).then(signed => {
        var tran = _web3.eth.sendSignedTransaction(signed.rawTransaction);
        tran.on('transactionHash', hash => {
            console.log('hash');
            console.log(hash);
            return;
        });
        tran.on('error', err => {
            console.error(err);
            return;
        });
    });
}

async function getCurrentBlockNum(_web3) {
    try{
        return await _web3.eth.getBlockNumber();
    } 
    catch(e) {
        console.log("unable to get block number, retrying...")
        return await getCurrentBlockNum(_web3);
    }
}

async function getPastEvents(_contract, _eventName, _fromBlock) {
    try{
        return await _contract.getPastEvents(_eventName, {fromBlock: _fromBlock});
    } 
    catch(e) {
        console.log("unable to get events, retrying...")
        return await getPastEvents(_contract,_eventName, _fromBlock);
    }
}

async function waitForSecond(_time) {
    for(let i = 0; i < _time; ++i) {
        console.log("Waiting for " , _time - i, " seconds...");
        await new Promise(r => setTimeout(r, 1000));
    }
}
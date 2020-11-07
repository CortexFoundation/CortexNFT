pragma solidity ^0.4.24;

import "./Artwork.sol";
import "./CRC4/ICRC4.sol";
import "./CRC4/ICRC4Receiver.sol";

contract NFTCrossChainMinter is ICRC4Receiver{
    bytes4 private constant _INTERFACE_ID_CRC4 = 0x80ac58cd;
    
    event Lock(address indexed _from, address indexed _nftAddr, uint256 indexed _tokenId);
    event RegisterSuccess(address indexed _nftCortexAddr, address indexed _nftEthereumAddr);

    // All the CRC4 contract could use NFTLocker to deal with cross-chain asset trading, 
    // and will create a ERC721 contract on the ethereum associated with original contract on cortex
    // after completly register success and create contract on the ethereum, will set the map
    mapping(address => address) public cortex2Ethereum;
    
    address public governance;

    constructor() {
        governance = msg.sender;
    }

    function Register(address _nftAddr, string memory _seriesName) public {
        require(cortex2Ethereum[_nftAddr] == address(0), "already registered");
        // verify the contract is a CRC4 contract.
        require(ICRC4(_nftAddr).supportsInterface(_INTERFACE_ID_CRC4), 
            "this contract address does not implement the CRC4");
        address newNft = new Artwork(_seriesName);
        cortex2Ethereum[_nftAddr] = newNft;
        emit RegisterSuccess(_nftAddr, newNft);
    }

    function resetMapping(address _nftCortexAddr, address _nftEthereumAddr) public {
        require(msg.sender == governance, " only governance could setup this mapping");
        cortex2Ethereum[_nftCortexAddr] = _nftEthereumAddr;
        emit RegisterSuccess(_nftCortexAddr, _nftEthereumAddr);
    }

}
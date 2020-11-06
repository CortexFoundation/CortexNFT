pragma solidity ^0.4.24;

import "./CRC4/ICRC4.sol";
import "./CRC4/ICRC4Receiver.sol";

contract NFTLocker is ICRC4Receiver{
    // All the CRC4 contract could use NFTLocker to deal with cross-chain asset trading, 
    // and will create a ERC721 contract on the ethereum associated with original contract on cortex
    // after completly register success and create contract on the ethereum, will set the map
    mapping(address => address) cortex2Ethereum; 

    bytes4 private constant _CRC4_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_CRC4 = 0x80ac58cd;
    
    event Lock(address indexed from, address indexed nftAddr, uint256 indexed tokenId);
    event Register(address indexed nftAddr);
    event RegisterSuccess(address indexed _NFTCortexAddr, address indexed _NFTEthereumAddr);
    
    address public governance;

    constructor() {
        governance = msg.sender;
    }

    function Register(address _NFTAddr) {
        // verify the contract is a CRC4 contract.
        require(ICRC4(_NFTAddr).supportsInterface(_INTERFACE_ID_CRC4), 
            "this contract address does not implement the CRC4");
        emit Register(_NFTAddr);
    }

    function setMapping(address _NFTCortexAddr, address _NFTEthereumAddr) {
        require(msg.sender == governance, " only governance could setup this mapping");
        cortex2Ethereum[_NFTCortexAddr] = _NFTEthereumAddr;
        emit RegisterSuccess(_NFTCortexAddr, _NFTEthereumAddr);
    }
    function onCRC4Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes memory data
    )
        public returns (bytes4) 
    {
        return _CRC4_RECEIVED;
    }

    function lockNFT(address _nftAddr, uint256 _tokenId) external {
        require(ICRC4(_nftAddr).supportsInterface(_INTERFACE_ID_CRC4), "not CRC4");
        require(cortex2Ethereum[_NFTAddr] != address(0), "the contract has not register the crosse-chain service now!");
        ICRC4(_NFTAddr).safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Lock(msg.sender, _NFTAddr, _tokenId);
    }

}
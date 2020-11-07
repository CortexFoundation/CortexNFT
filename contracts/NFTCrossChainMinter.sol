pragma solidity ^0.4.24;

import "./CrossChainArtwork.sol";
import "./CRC4/ICRC4.sol";
import "./CRC4/ICRC4Receiver.sol";

contract NFTCrossChainMinter is ICRC4Receiver {
    bytes4 private constant _CRC4_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_CRC4 = 0x80ac58cd;
    
    event Lock(address indexed _from, address indexed _nftAddr, uint256 indexed _tokenId);
    event Register(address indexed _nftSourceAddr, address indexed _nftTargetAddr);

    // All the CRC4 contract could use NFTLocker to deal with cross-chain asset trading, 
    // and will create a ERC721 contract on the Target chain associated with original contract on Source
    // after completly register success and create contract on the Target chain, will set the map
    mapping(address => address) public crossChainNftAddr;
    
    address public governance;

    constructor() {
        governance = msg.sender;
    }

    function register(address _nftAddr, string memory _seriesName) public {
        require(crossChainNftAddr[_nftAddr] == address(0), "already registered");
        // verify the contract is a CRC4 contract.
        require(ICRC4(_nftAddr).supportsInterface(_INTERFACE_ID_CRC4), 
            "this contract address does not implement the CRC4");
        address newNft = new Artwork(_seriesName);
        crossChainNftAddr[_nftAddr] = newNft;
        emit Register(_nftAddr, newNft);
    }

    function resetMapping(address _nftSourceAddr, address _nftTargetAddr) public {
        require(msg.sender == governance, "only governance could setup this mapping");
        crossChainNftAddr[_nftSourceAddr] = _nftTargetAddr;
        emit Register(_nftSourceAddr, _nftTargetAddr);
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
        require(crossChainNftAddr[_nftAddr] != address(0), "the contract has not register the crosse-chain service now!");
        ICRC4(_nftAddr).safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Lock(msg.sender, _nftAddr, _tokenId);
    }

    function mintNFT(address _nftAddr, address _owner, uint256 _tokenId, string memory _tokenURI) external {
        require(msg.sender == governance, "not goernance");
        CrossChainArtwork(crossChainNftAddr[_nftAddr]).addItemByTokenID(_owner, _tokenId, _tokenURI);
    }
}
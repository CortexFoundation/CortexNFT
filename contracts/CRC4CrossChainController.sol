pragma solidity ^0.4.24;

import "./CrossChainArtwork.sol";
import "./CRC4/ICRC4.sol";
import "./CRC4/ICRC4Receiver.sol";

contract CRC4CrossChainController is ICRC4Receiver {
    bytes4 private constant _CRC4_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_CRC4 = 0x80ac58cd;
    
    event Lock(address indexed _from, address indexed _nftAddr, uint256 indexed _tokenId);
    event Register(address indexed _nftSourceAddr, address indexed _nftTargetAddr);

    // All the CRC4 contract could use NFTLocker to deal with cross-chain asset trading, 
    // and will create a ERC721 contract on the Target chain associated with original contract on Source
    // after completly register success and create contract on the Target chain, will set the map
    mapping(address => address) public CRC4ToERC721;
    mapping(address => address) public ERC721ToCRC4;
    
    address public governance;

    constructor() {
        governance = msg.sender;
    }

    // pls make sure _ERC721Addr implement the ERC721 standard
    function register(address _ERC721Addr, string memory _seriesName) public {
        require(ERC721ToCRC4[_ERC721Addr] == address(0), "already registered");
        address newCRC4 = new Artwork(_seriesName);
        ERC721ToCRC4[ _ERC721Addr] = newCRC4;
        CRC4ToERC721[newCRC4] = _ERC721Addr;
        emit Register(_ERC721Addr, newCRC4);
    }

    // actually it's not as useful we thought 
    function resetMapping(address _ERC721Addr, address _CRC4Addr) public {
        require(msg.sender == governance, "only governance could setup this mapping");
        oldCRC4Addr = ERC721ToCRC4[_ERC721Addr];
        ERC721ToCRC4[_ERC721Addr] = _CRC4Addr;
        CRC4ToERC721[oldCRC4Addr] = address(0);
        emit Register(_ERC721Addr, _CRC4Addr);
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

    function lockCRC4(address _CRC4Addr, uint256 _tokenId) external {
        require(CRC4ToERC721[_CRC4Addr] != address(0), "the contract has not register the crosse-chain service now!");
        ICRC4(_CRC4Addr).safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Lock(msg.sender, _CRC4Addr, _tokenId);
    }

    function mintCRC4(address _ERC721Addr, address _owner, uint256 _tokenId, string memory _tokenURI) external {
        require(msg.sender == governance, "not goernance");
        CrossChainArtwork(ERC721ToCRC4[_ERC721Addr]).addItemByTokenID(_owner, _tokenId, _tokenURI);
    }
}
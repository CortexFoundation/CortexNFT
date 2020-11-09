pragma solidity ^0.6.0;

import "./CrossChainArtwork.sol";
import "@openzeppelin/contracts/IERC721.sol";
import "@openzeppelin/contracts/IERC721Receiver.sol";

contract ERC721CrossChainController is IERC7214Receiver {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    
    event Lock(address indexed _from, address indexed _nftAddr, uint256 indexed _tokenId);
    event Register(address indexed _nftSourceAddr, address indexed _nftTargetAddr);

    // All the ERC721 contract could use NFTLocker to deal with cross-chain asset trading, 
    // and will create a ERC721 contract on the Target chain associated with original contract on Source
    // after completly register success and create contract on the Target chain, will set the map
    mapping(address => address) public CRC4ToERC721;
    mapping(address => address) public ERC721ToCRC4;
    
    address public governance;

    constructor() {
        governance = msg.sender;
    }

    // pls make sure _ERC721Addr implement the ERC721 standard
    function register(address _CRC4Addr, string memory _seriesName) public {
        require(CRC4ToERC721[_CRC4Addr] == address(0), "already registered");
        address newERC721 = new Artwork(_seriesName);
        CRC4ToERC721[ _CRC4Addr] = newERC721;
        ERC721ToCRC4[newERC721] = _CRC4Addr;
        emit Register(_CRC4Addr, newERC721);
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

    function lockCRC4(address _ERC721Addr, uint256 _tokenId) external {
        require(ERC721ToCRC4[_ERC721Addr] != address(0), "the contract has not register the crosse-chain service now!");
        IERC721(_ERC721Addr).safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Lock(msg.sender, _ERC721Addr, _tokenId);
    }

    function mintCRC4(address _CRC4Addr, address _owner, uint256 _tokenId, string memory _tokenURI) external {
        require(msg.sender == governance, "not goernance");
        CrossChainArtwork(CRC4ToERC721[_CRC4Addr]).addItemByTokenID(_owner, _tokenId, _tokenURI);
    }
}
pragma solidity ^0.4.24;

import "./CrossChainArtwork.sol";
import "./CRC4/ICRC4.sol";
import "./CRC4/ICRC4Receiver.sol";
import "./utils/Ownable.sol";

contract CrossChainController is ICRC4Receiver, Ownable {
    bytes4 private constant _CRC4_RECEIVED = 0xef0b63ff;
    bytes4 private constant _INTERFACE_ID_CRC4 = 0x80ac58cd;
    
    event Lock(address indexed _from, address indexed _nftAddr, uint256 indexed _tokenId);
    event Register(address indexed _nftSourceAddr, address indexed _nftTargetAddr);
    event Burn(address indexed _nftAddr, uint256 indexed _tokenId);

    // All the CRC4 contract could use NFTLocker to deal with cross-chain asset trading, 
    // and will create a ERC721 contract on the Target chain associated with original contract on Source
    // after completly register success and create contract on the Target chain, will set the map
    mapping(address => address) public nftCrossChainMapping;
    mapping(address => address) public nftReverseMapping;
    mapping(address => bool) public lockRegistered;

    // pls make sure _nftSourceAddr implement the ERC721 standard
    function registerMinter(address _nftSourceAddr, string memory _name, string memory _symbol, string memory _seriesName) public {
        require(nftCrossChainMapping[_nftSourceAddr] == address(0), "already registered");
        address newTargetNft = new CrossChainArtwork(_name, _symbol, _seriesName);
        CrossChainArtwork(newTargetNft).setApprovalForAll(address(this), true);
        nftCrossChainMapping[_nftSourceAddr] = newTargetNft;
        // for returning minted cross chain NFT
        nftReverseMapping[newTargetNft] = _nftSourceAddr;
        emit Register(_nftSourceAddr, newTargetNft);
    }

    function registerLocker(address _sourceNftAddr, address _crossedNftAddr) public onlyOwner {
        lockRegistered[_sourceNftAddr] = true;
        nftReverseMapping[_crossedNftAddr] = _sourceNftAddr;
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

    function lock(address _nftAddr, uint256 _tokenId) external {
        if(lockRegistered[_nftAddr]) {
            ICRC4(_nftAddr).safeTransferFrom(msg.sender, address(this), _tokenId);
            emit Lock(msg.sender, _nftAddr, _tokenId);
        }
        else if(nftReverseMapping[_nftAddr] != address(0)) {
            CrossChainArtwork(_nftAddr).burn(_tokenId);
            emit Burn(_nftAddr, _tokenId);
        }
        else {
            revert();
        }
    }

    function mint(address _nftAddr, address _owner, uint256 _tokenId, string _tokenURI) external onlyOwner {
        // if is a returning NFT
        if(nftReverseMapping[_nftAddr] != address(0)) {
            ICRC4(nftReverseMapping[_nftAddr]).safeTransferFrom(address(this), _owner, _tokenId);
        }
        else{
            CrossChainArtwork(nftCrossChainMapping[_nftAddr]).addItemByTokenID(_owner, _tokenId, _tokenURI);
        }
    }
}
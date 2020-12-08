pragma solidity ^0.4.24;

import "./ERC721CrossChainArtwork.sol";
import "./ERC721/IERC721.sol";
import "./ERC721/IERC721Receiver.sol";
import "./utils/Ownable.sol";

contract ERC721CrossChainController is IERC721Receiver, Ownable {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    
    event Lock(address indexed _from, address indexed _nftAddr, uint256 indexed _tokenId);
    event Register(address indexed _nftSourceAddr, address indexed _nftTargetAddr);
    event Burn(address indexed _nftAddr, uint256 indexed _tokenId);

    // All the ERC721 contract could use NFTLocker to deal with cross-chain asset trading, 
    // and will create a ERC721 contract on the Target chain associated with original contract on Source
    // after completly register success and create contract on the Target chain, will set the map
    mapping(address => address) public nftCrossChainMapping;
    mapping(address => address) public nftReverseMapping;
    mapping(address => bool) public lockRegistered;
    
    // pls make sure _nftSourceAddr implement the ERC721 standard
    function registerMinter(address _nftSourceAddr, string memory _name, string memory _symbol, string memory _seriesName) public {
        require(nftCrossChainMapping[_nftSourceAddr] == address(0), "already registered");
        address newTargetNft = new ERC721CrossChainArtwork(_name, _symbol, _seriesName);
        ERC721CrossChainArtwork(newTargetNft).setApprovalForAll(address(this), true);
        nftCrossChainMapping[_nftSourceAddr] = newTargetNft;
        // for returning minted cross chain NFT
        nftReverseMapping[newTargetNft] = _nftSourceAddr;
        emit Register(_nftSourceAddr, newTargetNft);
    }

    function registerLocker(address _sourceNftAddr, address _crossedNftAddr) public onlyOwner {
        lockRegistered[_sourceNftAddr] = true;
        nftReverseMapping[_crossedNftAddr] = _sourceNftAddr;
    }


    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes memory data
    )
        public returns (bytes4) 
    {
        return _ERC721_RECEIVED;
    }

    function lock(address _nftAddr, uint256 _tokenId) external {
        // lock original piece
        if(lockRegistered[_nftAddr]) {
            IERC721(_nftAddr).safeTransferFrom(msg.sender, address(this), _tokenId);
            emit Lock(msg.sender, _nftAddr, _tokenId);
        }
        // burn returning piece
        else if(nftReverseMapping[_nftAddr] != address(0)) {
            ERC721CrossChainArtwork(_nftAddr).burn(_tokenId);
            emit Burn(_nftAddr, _tokenId);
        }
        else {
            revert();
        }
    }

    function mint(address _nftAddr, address _owner, uint256 _tokenId, string _tokenURI) external onlyOwner {
        // if is a returning NFT
        if(nftReverseMapping[_nftAddr] != address(0)) {
            IERC721(nftReverseMapping[_nftAddr]).safeTransferFrom(address(this), _owner, _tokenId);
        }
        else{
            ERC721CrossChainArtwork(nftCrossChainMapping[_nftAddr]).addItemByTokenID(_owner, _tokenId, _tokenURI);
        }
    }
}
pragma solidity ^0.4.24;

import "./CRC4/ICRC4.sol";
import "./CRC4/ICRC4Receiver.sol";

contract NFTLocker is ICRC4Receiver{
    bytes4 private constant _CRC4_RECEIVED = 0x150b7a02;
    
    event Lock(address indexed from, address indexed nftAddr, uint256 indexed tokenId);
    
    address public governance;

    constructor() {
        governance = msg.sender;
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
        ICRC4(_nftAddr).safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Lock(msg.sender, _nftAddr, _tokenId);
    }

}
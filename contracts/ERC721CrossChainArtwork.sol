pragma solidity ^0.4.24;

import "./ERC721/ERC721Full.sol";
import "./utils/Counters.sol";
import "./utils/Ownable.sol";

contract ERC721CrossChainArtwork is ERC721Full, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public seriesName;

    constructor(string memory _name, string memory _symbol, string memory _seriesName) 
        ERC721Full(_name, _symbol) public 
    {
        seriesName = _seriesName;
    }
    
    function addItemByTokenID(address _owner, uint256 _tokenID, string memory _tokenURI) public onlyOwner {
        _tokenIds.increment();
        _mint(_owner, _tokenID);
        _setTokenURI(_tokenID, _tokenURI);
    }
}

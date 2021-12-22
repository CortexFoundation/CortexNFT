pragma solidity ^0.8.7;

import "./CRC4/CRC4Burnable.sol";
import "./CRC4/CRC4Full.sol";
import "./utils/Counters.sol";
import "./utils/Ownable.sol";

contract Artwork is CRC4Full, CRC4Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public seriesName;

    constructor(string memory _name, string memory _symbol, string memory _seriesName) 
        CRC4Full(_name, _symbol) public 
    {
        seriesName = _seriesName;
    }

    function addItem(address _owner, string memory _tokenURI) public onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(_owner, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        return newItemId;
    }

    function addItems(address _owner, string memory _tokenURI, uint _numberOfItems) public onlyOwner {
        uint256 newItemId;
        for(uint i = 0; i < _numberOfItems; ++i) {
            _tokenIds.increment();

            newItemId = _tokenIds.current();
            _mint(_owner, newItemId);
            _setTokenURI(newItemId, _tokenURI);
        }
    }

    function burnBatch(uint256[] memory _ids) public {
        for(uint i = 0; i <_ids.length; ++i) {
            burn(_ids[i]);
        }
    }
}

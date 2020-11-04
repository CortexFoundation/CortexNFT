pragma solidity ^0.4.24;

import "./CRC4/CRC4Full.sol";
import "./utils/Counters.sol";

contract Artwork is CRC4Full {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() CRC4Full("ARTWORK", "AW") public {
    }

    function addItem(address _owner, string memory _tokenURI) public returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(_owner, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        return newItemId;
    }

    function addItems(address _owner, string memory _tokenURI, uint _numberOfItems) public {
        uint256 newItemId;
        for(uint i = 0; i < _numberOfItems; ++i) {
            _tokenIds.increment();

            newItemId = _tokenIds.current();
            _mint(_owner, newItemId);
            _setTokenURI(newItemId, _tokenURI);
        }
    }
}

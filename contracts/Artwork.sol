pragma solidity ^0.4.24;

import "./CRC4/CRC4Full.sol";
import "./utils/Counters.sol";

contract Artwork is CRC4Full {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() CRC4Full("ARTWORK", "AW") public {
    }

    function addItem(address creator, string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(creator, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}

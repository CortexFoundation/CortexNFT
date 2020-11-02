pragma solidity ^0.4.24;

import "./ERC721/ERC721Full.sol";
import "./utils/Counters.sol";

contract artwork is ERC721Full {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721Full("ARTWORK", "AW") public {
    }

    function addItem(address creator, string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}

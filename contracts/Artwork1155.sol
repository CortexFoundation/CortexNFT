// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Artwork1155 is ERC1155, Ownable {

    constructor(string memory _uri) 
        ERC1155(_uri) public 
    {
        
    }

    function mint(address _owner, uint256 _tokenId, uint256 _amount) public onlyOwner {
        require(_amount > 0);
        _mint(_owner, _tokenId, _amount, "");
    }

    function mint(address _owner, uint256 _tokenId, uint256 _amount, bytes memory data) public onlyOwner {
        require(_amount > 0);
        _mint(_owner, _tokenId, _amount, data);
    }

    // function burnBatch(uint256[] memory _ids) public {
    //     for(uint i = 0; i <_ids.length; ++i) {
    //         burn(_ids[i]);
    //     }
    // }
}

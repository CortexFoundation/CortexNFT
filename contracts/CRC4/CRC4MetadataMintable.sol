pragma solidity ^0.4.24;

import "./CRC4Metadata.sol";
import "../utils/MinterRole.sol";


/**
 * @title CRC4MetadataMintable
 * @dev CRC4 minting logic with metadata.
 */
contract CRC4MetadataMintable is CRC4, CRC4Metadata, MinterRole {
    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @param tokenURI The token URI of the minted token.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return true;
    }
}

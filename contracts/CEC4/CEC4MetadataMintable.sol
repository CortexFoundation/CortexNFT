pragma solidity ^0.4.24;

import "./CEC4Metadata.sol";
import "../utils/MinterRole.sol";


/**
 * @title CEC4MetadataMintable
 * @dev CEC4 minting logic with metadata.
 */
contract CEC4MetadataMintable is CEC4, CEC4Metadata, MinterRole {
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

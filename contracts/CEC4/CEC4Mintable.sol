pragma solidity ^0.4.24;

import "./CEC4.sol";
import "../utils/MinterRole.sol";

/**
 * @title CEC4Mintable
 * @dev CEC4 minting logic.
 */
contract CEC4Mintable is CEC4, MinterRole {
    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }
}

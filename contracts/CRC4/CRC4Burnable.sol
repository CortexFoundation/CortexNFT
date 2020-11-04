pragma solidity ^0.4.24;

import "./CRC4.sol";

/**
 * @title CRC4 Burnable Token
 * @dev CRC4 Token that can be irreversibly burned (destroyed).
 */
contract CRC4Burnable is CRC4 {
    /**
     * @dev Burns a specific CRC4 token.
     * @param tokenId uint256 id of the CRC4 token to be burned.
     */
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "CRC4Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

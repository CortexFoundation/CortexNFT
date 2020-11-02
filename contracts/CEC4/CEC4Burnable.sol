pragma solidity ^0.4.24;

import "./CEC4.sol";

/**
 * @title CEC4 Burnable Token
 * @dev CEC4 Token that can be irreversibly burned (destroyed).
 */
contract CEC4Burnable is CEC4 {
    /**
     * @dev Burns a specific CEC4 token.
     * @param tokenId uint256 id of the CEC4 token to be burned.
     */
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "CEC4Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

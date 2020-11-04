pragma solidity ^0.4.24;

import "./CRC4.sol";
import "./CRC4Enumerable.sol";
import "./CRC4Metadata.sol";

/**
 * @title Full CRC4 Token
 * This implementation includes all the required and some optional functionality of the CRC4 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract CRC4Full is CRC4, CRC4Enumerable, CRC4Metadata {
    constructor (string memory name, string memory symbol) public CRC4Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

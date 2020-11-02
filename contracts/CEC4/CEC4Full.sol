pragma solidity ^0.4.24;

import "./CEC4.sol";
import "./CEC4Enumerable.sol";
import "./CEC4Metadata.sol";

/**
 * @title Full CEC4 Token
 * This implementation includes all the required and some optional functionality of the CEC4 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract CEC4Full is CEC4, CEC4Enumerable, CEC4Metadata {
    constructor (string memory name, string memory symbol) public CEC4Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

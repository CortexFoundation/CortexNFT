pragma solidity ^0.4.24;

import "./ICRC4Receiver.sol";

contract CRC4Holder is ICRC4Receiver {
    function onCRC4Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onCRC4Received.selector;
    }
}

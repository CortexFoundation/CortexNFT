pragma solidity ^0.4.24;

import "./ICEC4Receiver.sol";

contract CEC4Holder is ICEC4Receiver {
    function onCEC4Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onCEC4Received.selector;
    }
}

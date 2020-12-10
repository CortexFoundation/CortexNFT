pragma solidity ^0.4.24;

import "./CRC4/CRC4Full.sol";
import "./utils/Counters.sol";
import "./utils/Ownable.sol";

contract CortexArtProxy {
    address implementation;

    // function() external payable {
    //     assembly {
    //         let ptr := mload(0x40)

    //         // (1) copy incoming call data
    //         calldatacopy(ptr, 0, calldatasize)

    //         // (2) forward call to logic contract
    //         let result := delegatecall(gas, implementation, ptr, calldatasize, 0, 0)
    //         let size := returndatasize

    //         // (3) retrieve return data
    //         returndatacopy(ptr, 0, size)

    //         // (4) forward return data back to caller
    //         switch result
    //         case 0 { revert(ptr, size) }
    //         default { return(ptr, size) }
    //     }
    // }
}

pragma solidity ^0.8.7;

import "./Initializable.sol";

import "./CRC4MetadataUpgradeable.sol";
import "./CRC4EnumerableUpgradeable.sol";
import "./CRC4Upgradeable.sol";

/**
 * @title CRC4 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract CRC4FullUpgradeable is Initializable, CRC4Upgradeable, CRC4MetadataUpgradeable, CRC4EnumerableUpgradeable {

    function initialize (string memory name, string memory symbol) public initializer {
        CRC4Upgradeable.initialize();
        CRC4MetadataUpgradeable.initialize(name, symbol);
        CRC4EnumerableUpgradeable.initialize();
    }
    
}

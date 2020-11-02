pragma solidity ^0.4.24;

import "./ICEC3.sol";

/**
 * @dev Implementation of the `ICEC3` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract CEC3 is ICEC3 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_CEC3 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for CEC3 itself here
        _registerInterface(_INTERFACE_ID_CEC3);
    }

    /**
     * @dev See `ICEC3.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual CEC3 interface is automatic and
     * registering its interface id is not required.
     *
     * See `ICEC3.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the CEC3 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "CEC3: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

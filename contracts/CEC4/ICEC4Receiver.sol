pragma solidity ^0.4.24;

/**
 * @title CEC4 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from CEC4 asset contracts.
 */
contract ICEC4Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The CEC4 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onCEC4Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the CEC4 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onCEC4Received(address,address,uint256,bytes)"))`
     */
    function onCEC4Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

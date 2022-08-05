// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Event {
    // An event whenever the platform address is updated
    event PlatformAddressUpdated(address platformAddress);

    // An event whenever royalty amount for a token is updated
    event PlatformSalePercentageUpdated(
        uint256 tokenId,
        uint256 platformFirstPercentage,
        uint256 platformSecondPercentage
    );

    // An event whenever artist secondary sale percentage is updated
    event ArtistSecondSalePercentUpdated(uint256 artistSecondPercentage);

    // An event whenever a bid is proposed
    event BidProposed(uint256 tokenId, uint256 bidAmount, address bidder);

    // An event whenever an bid is withdrawn
    event BidWithdrawn(uint256 tokenId);

    // An event when an auction is created
    event AuctionCreated(uint256 tokenId, uint256 startTime, uint256 endTime);

    // An event when auction cancelled
    event AuctionCancelled(uint256 tokenId);

    // An event whenever a buy now price has been set
    event BuyPriceSet(uint256 tokenId, uint256 price);

    // An event when a token has been sold
    event TokenSale(
        // the id of the token
        uint256 tokenId,
        // the price that the token was sold for
        uint256 salePrice,
        // the address of the buyer
        address buyer
    );
}

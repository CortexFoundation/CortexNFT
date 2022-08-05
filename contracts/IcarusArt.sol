// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Event.sol";
import "./CortexArtERC721.sol";

contract IcarusArt is Event {
    // selling state of the artwork
    struct SellingState {
        uint256 buyPrice;
        uint256 reservePrice;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
    }

    // struct for a pending bid
    struct PendingBid {
        // the address of the bidder
        address bidder;
        // the amount that they bid
        uint256 amount;
        // false by default, true once instantiated
        bool exists;
    }

    // The maximum time period an auction can open for
    uint256 public maximumAuctionPeriod = 7 days;
    // The maximum time before the auction go live
    uint256 public maximumAuctionPreparingTime = 3 days;
    uint256 public maximumPiecePerCreator = 20;
    uint256 public maximumPiecePeriod = 30 days;
    // track whether this token was sold the first time or not (used for determining whether to use first or secondary sale percentage)
    mapping(uint256 => bool) public tokenDidHaveFirstSale;
    // mapping of addresses to credits for failed transfers
    mapping(address => uint256) public failedTransferCredits;
    // mapping of tokenId to percentage of sale that the platform gets on first sales
    mapping(uint256 => uint256) public platformFirstSalePercentages;
    // mapping of tokenId to percentage of sale that the platform gets on secondary sales
    mapping(uint256 => uint256) public platformSecondSalePercentages;
    // map a control token ID to its selling state
    mapping(uint256 => SellingState) public sellingState;
    // map a control token ID to its highest bid
    mapping(uint256 => PendingBid) public pendingBids;
    // the percentage of sale that an artist gets on secondary sales
    uint256 public artistSecondSalePercentage;
    // the minimum % increase for new bids coming
    uint256 public minBidIncreasePercent;
    // the address of the platform (for receiving commissions and royalties)
    address public platformAddress;

    CortexArtERC721 artToken;

    constructor(address _tokenAddr) {
        artToken = CortexArtERC721(_tokenAddr);
        // starting royalty amounts
        artistSecondSalePercentage = 10;
        // initialize the minimum bid increase percent
        minBidIncreasePercent = 1;
        // by default, the platformAddress is the address that deploy this contract
        platformAddress = msg.sender;
    }

    // modifier for only allowing the platform to make a call
    modifier onlyPlatform() {
        require(msg.sender == platformAddress);
        _;
    }

    // Allows the current platform address to update to something different
    function updatePlatformAddress(address _newPlatformAddress) external onlyPlatform {
        platformAddress = _newPlatformAddress;

        emit PlatformAddressUpdated(_newPlatformAddress);
    }

    // Allows platform to waive the first sale requirement for a token (for charity events, special cases, etc)
    function waiveFirstSaleRequirement(uint256 _tokenId) external onlyPlatform {
        // This allows the token sale proceeds to go to the current owner (rather than be distributed amongst the token's creators)
        tokenDidHaveFirstSale[_tokenId] = true;
    }

    function setMaximumPiecePerCreator(uint256 _maximumPiecePerCreator) external onlyPlatform {
        require(_maximumPiecePerCreator > 0);
        maximumPiecePerCreator = _maximumPiecePerCreator;
    }

    function setMaximumPiecePeriod(uint256 _maximumPiecePeriod) external onlyPlatform {
        require(_maximumPiecePeriod > 0);
        maximumPiecePeriod = _maximumPiecePeriod;
    }

    // Allows platform to change the royalty percentage for a specific token
    function updatePlatformSalePercentage(
        uint256 _tokenId,
        uint256 _platformFirstSalePercentage,
        uint256 _platformSecondSalePercentage
    ) external onlyPlatform {
        // set the percentages for this token
        platformFirstSalePercentages[_tokenId] = _platformFirstSalePercentage;
        platformSecondSalePercentages[_tokenId] = _platformSecondSalePercentage;
        // emit an event to notify that the platform percent for this token has changed
        emit PlatformSalePercentageUpdated(
            _tokenId,
            _platformFirstSalePercentage,
            _platformSecondSalePercentage
        );
    }

    // Allows the platform to change the minimum percent increase for incoming bids
    function updateMinimumBidIncreasePercent(uint256 _minBidIncreasePercent) external onlyPlatform {
        require(
            (_minBidIncreasePercent > 0) && (_minBidIncreasePercent <= 50),
            "Bid increases must be within 0-50%"
        );
        // set the new bid increase percent
        minBidIncreasePercent = _minBidIncreasePercent;
    }

    function updateMaximumAuctionPeriod(uint256 _maxPeriod, uint256 _maxPrepTime)
        external
        onlyPlatform
    {
        maximumAuctionPeriod = _maxPeriod;
        maximumAuctionPreparingTime = _maxPrepTime;
    }

    // Allows platform to change the percentage that artists receive on secondary sales
    function updateArtistSecondSalePercentage(uint256 _artistSecondSalePercentage)
        external
        onlyPlatform
    {
        // update the percentage that artists get on secondary sales
        artistSecondSalePercentage = _artistSecondSalePercentage;
        // emit an event to notify that the artist second sale percent has updated
        emit ArtistSecondSalePercentUpdated(artistSecondSalePercentage);
    }

    function setSellingStates(
        uint256[] calldata _tokenId,
        uint256[] calldata _buyPrice,
        uint256[] calldata _startTime,
        uint256[] calldata _endTime,
        uint256[] calldata _reservePrice
    ) external {
        for (uint256 i; i < _tokenId.length; ++i) {
            setSellingState(
                _tokenId[i],
                _buyPrice[i],
                _startTime[i],
                _endTime[i],
                _reservePrice[i]
            );
        }
    }

    function setSellingState(
        uint256 _tokenId,
        uint256 _buyPrice,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _reservePrice
    ) public {
        require(isApprovedOrOwner(msg.sender, _tokenId), "Not the owner!");
        require(pendingBids[_tokenId].exists == false, "On sale!");
        if (_startTime != 0 || _endTime != 0) {
            require(
                sellingState[_tokenId].auctionStartTime > block.timestamp ||
                    sellingState[_tokenId].auctionEndTime < block.timestamp,
                "There is an existing auction"
            );
            require(
                block.timestamp + maximumAuctionPreparingTime >= _startTime,
                "Exceed max preparing time"
            );
            require(_startTime + maximumAuctionPeriod >= _endTime, "Exceed max auction time!");
            sellingState[_tokenId] = SellingState(_buyPrice, _reservePrice, _startTime, _endTime);
            emit AuctionCreated(
                _tokenId,
                sellingState[_tokenId].auctionStartTime,
                sellingState[_tokenId].auctionEndTime
            );
        } else {
            sellingState[_tokenId] = SellingState(_buyPrice, 0, 0, 0);
            emit AuctionCancelled(_tokenId);
        }
        // emit event
        emit BuyPriceSet(_tokenId, _buyPrice);
    }

    // Allow the owner to sell a piece through auction
    function openAuction(
        uint256 _tokenId,
        uint256 _prepTime,
        uint256 _auctionTime,
        uint256 _reservePrice
    ) external {
        require(isApprovedOrOwner(msg.sender, _tokenId), "Not the owner!");
        require(pendingBids[_tokenId].exists == false, "On sale!");
        require(
            sellingState[_tokenId].auctionEndTime < block.timestamp,
            "There is an existing auction"
        );
        require(_prepTime <= maximumAuctionPreparingTime, "Exceed max preparing time");
        require(_auctionTime <= maximumAuctionPeriod, "Exceed max auction time!");

        sellingState[_tokenId].auctionStartTime = block.timestamp + _prepTime;
        sellingState[_tokenId].auctionEndTime =
            sellingState[_tokenId].auctionStartTime +
            _auctionTime;
        sellingState[_tokenId].reservePrice = _reservePrice;
        emit AuctionCreated(
            _tokenId,
            sellingState[_tokenId].auctionStartTime,
            sellingState[_tokenId].auctionEndTime
        );
    }

    // Allow the owner to cancel the auction before it goes live
    function cancelAuction(uint256 _tokenId) external {
        require(isApprovedOrOwner(msg.sender, _tokenId), "Not the owner!");
        require(sellingState[_tokenId].auctionStartTime >= block.timestamp, "Too late!");
        sellingState[_tokenId].auctionEndTime = 0;
        sellingState[_tokenId].auctionStartTime = 0;
        emit AuctionCancelled(_tokenId);
    }

    // Bidder functions
    function bid(uint256 _tokenId) external payable {
        // cannot equal, don't allow bids of 0
        require(msg.value >= sellingState[_tokenId].reservePrice && msg.value > 0);
        // Check for auction expiring time
        require(
            sellingState[_tokenId].auctionStartTime <= block.timestamp,
            "Auction hasn't started!"
        );
        // Check for auction expiring time
        require(sellingState[_tokenId].auctionEndTime >= block.timestamp, "Auction expired!");
        // don't let owners/approved bid on their own tokens
        require(isApprovedOrOwner(msg.sender, _tokenId) == false);
        // check if there's a high bid
        if (pendingBids[_tokenId].exists) {
            // enforce that this bid is higher by at least the minimum required percent increase
            require(
                msg.value >= ((pendingBids[_tokenId].amount) * (minBidIncreasePercent + 100)) / 100,
                "Bid must increase by min %"
            );
            // Return bid amount back to bidder
            safeFundsTransfer(pendingBids[_tokenId].bidder, pendingBids[_tokenId].amount);
        }
        // set the new highest bid
        pendingBids[_tokenId] = PendingBid(msg.sender, msg.value, true);
        // Emit event for the bid proposal
        emit BidProposed(_tokenId, msg.value, msg.sender);
    }

    // allows an address with a pending bid to withdraw it
    function withdrawBid(uint256 _tokenId) external {
        // check that there is a bid from the sender to withdraw (also allows platform address to withdraw a bid on someone's behalf)
        require(msg.sender == platformAddress);
        require(pendingBids[_tokenId].exists);
        // Return bid amount back to bidder
        safeFundsTransfer(pendingBids[_tokenId].bidder, pendingBids[_tokenId].amount);
        // clear highest bid
        pendingBids[_tokenId] = PendingBid(address(0), 0, false);
        // emit an event when the highest bid is withdrawn
        emit BidWithdrawn(_tokenId);
    }

    // Allow anyone to accept the highest bid for a token
    function acceptBid(uint256 _tokenId) external {
        // can only be accepted when auction ended
        require(sellingState[_tokenId].auctionEndTime <= block.timestamp);
        // check if there's a bid to accept
        require(pendingBids[_tokenId].exists);
        // process the sale
        onTokenSold(_tokenId, pendingBids[_tokenId].amount, pendingBids[_tokenId].bidder);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(pendingBids[tokenId].exists == false, "Pending bid!");
        require(sellingState[tokenId].auctionEndTime == 0, "token on sale!");
        // prevent from unintended transfer
        sellingState[tokenId] = SellingState(0, 0, 0, 0);
        artToken.safeTransferFrom(from, to, tokenId);
    }

    // Allows owner of a control token to set an immediate buy price. Set to 0 to reset.
    function makeBuyPrice(uint256 _tokenId, uint256 _buyPrice) external {
        // check if sender is owner/approved of token
        require(isApprovedOrOwner(msg.sender, _tokenId));
        // set the buy price
        sellingState[_tokenId].buyPrice = _buyPrice;
        // emit event
        emit BuyPriceSet(_tokenId, _buyPrice);
    }

    // Buy the artwork for the currently set price
    // Allows the buyer to specify an expected remaining uses they'll accept
    function takeBuyPrice(uint256 _tokenId) external payable {
        // don't let owners/approved buy their own tokens
        require(isApprovedOrOwner(msg.sender, _tokenId) == false);
        // get the sale amount
        uint256 saleAmount = sellingState[_tokenId].buyPrice;
        // check that there is a buy price
        require(saleAmount > 0);
        // check that the buyer sent exact amount to purchase
        require(msg.value == saleAmount);
        // Return all highest bidder's money
        if (pendingBids[_tokenId].exists) {
            // Return bid amount back to bidder
            safeFundsTransfer(pendingBids[_tokenId].bidder, pendingBids[_tokenId].amount);
            // clear highest bid
            pendingBids[_tokenId] = PendingBid(address(0), 0, false);
        }
        onTokenSold(_tokenId, saleAmount, msg.sender);
    }

    // Allows a user to withdraw all failed transaction credits
    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];
        require(amount != 0);
        require(address(this).balance >= amount);
        failedTransferCredits[msg.sender] = 0;
        (bool successfulWithdraw, ) = msg.sender.call{value: amount}("");
        require(successfulWithdraw);
    }

    function getTokenOnSale() external view returns (uint256[] memory tokenIds) {
        uint256 tokenCount = 0;
        for (uint256 i = 1; i < artToken.expectedTokenSupply(); ++i) {
            if (sellingState[i].buyPrice > 0 || sellingState[i].auctionEndTime > block.timestamp) {
                ++tokenCount;
            }
        }
        tokenIds = new uint256[](tokenCount);
        tokenCount = 0;
        for (uint256 i = 1; i < artToken.expectedTokenSupply(); ++i) {
            if (sellingState[i].buyPrice > 0 || sellingState[i].auctionEndTime > block.timestamp) {
                tokenIds[tokenCount] = i;
                ++tokenCount;
            }
        }
    }

    // When a token is sold via list price or bid. Distributes the sale amount to the unique token creators and transfer
    // the token to the new owner
    function onTokenSold(
        uint256 _tokenId,
        uint256 _saleAmount,
        address _to
    ) private {
        // if the first sale already happened, then give the artist + platform the secondary royalty percentage
        if (tokenDidHaveFirstSale[_tokenId]) {
            uint256 platformAmount = (_saleAmount * platformSecondSalePercentages[_tokenId]) / 100;
            safeFundsTransfer(platformAddress, platformAmount);
            // distribute the creator royalty amongst the creators (all artists involved for a base token, sole artist creator for layer )
            uint256 creatorAmount = (_saleAmount * artistSecondSalePercentage) / 100;
            address[] memory creators = new address[](1);
            creators[0] = artToken.uniqueTokenCreators(_tokenId, 0);
            distributeFundsToCreators(creatorAmount, creators);
            address owner = artToken.ownerOf(_tokenId);
            // transfer the remaining amount to the owner of the token
            safeFundsTransfer(owner, _saleAmount - platformAmount - creatorAmount);
        } else {
            tokenDidHaveFirstSale[_tokenId] = true;
            uint256 platformAmount = (_saleAmount * platformFirstSalePercentages[_tokenId]) / 100;
            safeFundsTransfer(platformAddress, platformAmount);
            // this is a token first sale, so distribute the remaining funds to the unique token creators of this token
            // (if it's a base token it will be all the unique creators, if it's a control token it will be that single artist)
            // distributeFundsToCreators(saleAmount.sub(platformAmount), uniqueTokenCreators[_tokenId]);
            address[] memory owners = new address[](1);
            owners[0] = artToken.ownerOf(_tokenId);
            distributeFundsToCreators(_saleAmount - platformAmount, owners);
        }
        // clear highest bid
        pendingBids[_tokenId] = PendingBid(address(0), 0, false);
        // clear selling state
        sellingState[_tokenId] = SellingState(0, 0, 0, 0);
        // Transfer token to msg.sender
        artToken.safeTransferFrom(artToken.ownerOf(_tokenId), _to, _tokenId);
        // Emit event
        emit TokenSale(_tokenId, _saleAmount, _to);
    }

    // Take an amount and distribute it evenly amongst a list of creator addresses
    function distributeFundsToCreators(uint256 _amount, address[] memory _creators) private {
        uint256 creatorShare = _amount / (_creators.length);
        for (uint256 i = 0; i < _creators.length; i++) {
            safeFundsTransfer(_creators[i], creatorShare);
        }
    }

    // Safely transfer funds and if fail then store that amount as credits for a later pull
    function safeFundsTransfer(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount, gas: 2300}("");
        // if it failed, update their credit balance so they can pull it later
        if (success == false) {
            failedTransferCredits[recipient] = failedTransferCredits[recipient] + amount;
        }
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = artToken.ownerOf(_tokenId);
        return (_spender == owner ||
            artToken.isApprovedForAll(owner, _spender) ||
            artToken.getApproved(_tokenId) == _spender);
    }
}

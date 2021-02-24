pragma solidity ^0.4.24;

import "./CRC4/CRC4Full.sol";

contract CortexArt is CRC4Full {
    // An event whenever the platform address is updated
    event PlatformAddressUpdated(
        address platformAddress
    );

    event PermissionUpdated(
        uint256 tokenId,
        address tokenOwner,
        address permissioned
    );

    // An event whenever a creator is whitelisted with the token id and the layer count
    event CreatorWhitelisted(
        uint256 tokenId,
        uint256 layerCount,
        address creator
    );

    // An event whenever royalty amount for a token is updated
    event PlatformSalePercentageUpdated (
        uint256 tokenId,
        uint256 platformFirstPercentage,
        uint256 platformSecondPercentage        
    );

    // An event whenever artist secondary sale percentage is updated
    event ArtistSecondSalePercentUpdated (
        uint256 artistSecondPercentage
    );

    // An event whenever a bid is proposed
    event BidProposed(
        uint256 tokenId,
        uint256 bidAmount,
        address bidder
    );

    // An event whenever an bid is withdrawn
    event BidWithdrawn(
        uint256 tokenId
    );

    // An event when an auction is created
    event AuctionCreated (
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime
    );

    // An event when auction cancelled
    event AuctionCancelled (
        uint256 tokenId
    );

    // An event whenever a buy now price has been set
    event BuyPriceSet(
        uint256 tokenId,
        uint256 price
    );

    // An event when a token has been sold 
    event TokenSale(
        // the id of the token
        uint256 tokenId,
        // the price that the token was sold for
        uint256 salePrice,
        // the address of the buyer
        address buyer
    );

    // An event whenever a control token has been updated
    event ControlLeverUpdated(
        // the id of the token
        uint256 tokenId,
        // an optional amount that the updater sent to boost priority of the rendering
        uint256 priorityTip,
        // the number of times this control lever can now be updated
        int256 numRemainingUpdates,
        // the ids of the levers that were updated
        uint256[] leverIds,        
        // the previous values that the levers had before this update (for clients who want to animate the change)
        int256[] previousValues,
        // the new updated value
        int256[] updatedValues
    );

    // struct for a token that controls part of the artwork
    struct ControlToken {
        // number that tracks how many levers there are
        uint256 numControlLevers;
        // The number of update calls this token has (-1 for infinite)
        int256 numRemainingUpdates;
        // false by default, true once instantiated
        bool exists;
        // false by default, true once setup by the artist
        bool isSetup;
        // the levers that this control token can use
        mapping(uint256 => ControlLever) levers;
    }

    // struct for a lever on a control token that can be changed
    struct ControlLever {
        // // The minimum value this token can have (inclusive)
        int256 minValue;
        // The maximum value this token can have (inclusive)
        int256 maxValue;
        // The current value for this token
        int256 currentValue;
        // false by default, true once instantiated
        bool exists;
    }

    // strcut for the selling state of the artwork
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


    struct WhitelistReservation {
        // the address of the creator
        address creator;
        // the amount of layers they're expected to mint
        uint256 layerCount;
    }

    // The maxium time period an auction can open for
    uint256 public maximumAuctionPeriod = 7 days;
    // The maxium time before the auction go live
    uint256 public maximumAuctionPreparingTime = 3 days;
    // track whether this token was sold the first time or not (used for determining whether to use first or secondary sale percentage)
    mapping(uint256 => bool) public tokenDidHaveFirstSale;
    // if a token's URI has been locked or not
    mapping(uint256 => bool) public tokenURILocked;  
    // mapping of addresses to credits for failed transfers
    mapping(address => uint256) public failedTransferCredits;
    // mapping of tokenId to percentage of sale that the platform gets on first sales
    mapping(uint256 => uint256) public platformFirstSalePercentages;
    // mapping of tokenId to percentage of sale that the platform gets on secondary sales
    mapping(uint256 => uint256) public platformSecondSalePercentages;
    // users that are allowed to create artwork 
    mapping(address => bool) public artistWhitelist;
    // what tokenId creators are allowed to mint (and how many layers)
    mapping(uint256 => WhitelistReservation) public creatorWhitelist;
    // for each token, holds an array of the creator collaborators. For layer tokens it will likely just be [artist], for master tokens it may hold multiples
    mapping(uint256 => address[]) public uniqueTokenCreators;    
    // map a control token ID to its selling state
    mapping(uint256 => SellingState) public sellingState;
    // map a control token ID to its highest bid
    mapping(uint256 => PendingBid) public pendingBids;
    // map a control token id to a control token struct
    mapping(uint256 => ControlToken) public controlTokenMapping;    
    // mapping of addresses that are allowed to control tokens on your behalf
    mapping(address => mapping(uint256 => address)) public permissionedControllers;
    // the percentage of sale that an artist gets on secondary sales
    uint256 public artistSecondSalePercentage;
    // gets incremented to placehold for tokens not minted yet
    uint256 public expectedTokenSupply;
    // the minimum % increase for new bids coming
    uint256 public minBidIncreasePercent;
    // the address of the platform (for receving commissions and royalties)
    address public platformAddress;


    constructor
    (
        string memory _name, 
        string memory _symbol, 
        uint256 _initialExpectedTokenSupply
    ) 
        CRC4Full(_name, _symbol) public 
    {
        // starting royalty amounts
        artistSecondSalePercentage = 10;
        // intitialize the minimum bid increase percent
        minBidIncreasePercent = 1;
        // by default, the platformAddress is the address that mints this contract
        platformAddress = msg.sender;
        // set the initial expected token supply       
        expectedTokenSupply = _initialExpectedTokenSupply;
        require(expectedTokenSupply > 0);
    }


    // modifier for only allowing the platform to make a call
    modifier onlyPlatform() {
        require(msg.sender == platformAddress);
        _;
    }


    // whitelist an address as a artwork creator
    function whitelistUser(address _userAddr) external onlyPlatform {
        artistWhitelist[_userAddr] = true;
    }


    // reserve a tokenID and layer count for a _creator. Define a platform royalty percentage per art piece (some pieces have higher or lower amount)
    function whitelistTokenForCreator(address _creator, uint256 _masterTokenId, uint256 _layerCount, 
        uint256 _platformFirstSalePercentage, uint256 _platformSecondSalePercentage) external onlyPlatform {
        require(artistWhitelist[_creator] == true, "Creator not on the artist whitelist!");
        // the tokenID we're reserving must be the current expected token supply
        require(_masterTokenId == expectedTokenSupply);
        // Async pieces must have at least 1 layer
        require (_layerCount > 0);
        // reserve the tokenID for this _creator
        creatorWhitelist[_masterTokenId] = WhitelistReservation(_creator, _layerCount);
        // increase the expected token supply
        expectedTokenSupply = _masterTokenId.add(_layerCount).add(1);
        // define the platform percentages for this token here
        platformFirstSalePercentages[_masterTokenId] = _platformFirstSalePercentage;
        platformSecondSalePercentages[_masterTokenId] = _platformSecondSalePercentage;

        emit CreatorWhitelisted(_masterTokenId, _layerCount, _creator);
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


    // Allows platform to change the royalty percentage for a specific token
    function updatePlatformSalePercentage(uint256 _tokenId, uint256 _platformFirstSalePercentage, 
        uint256 _platformSecondSalePercentage) external onlyPlatform {
        // set the percentages for this token
        platformFirstSalePercentages[_tokenId] = _platformFirstSalePercentage;
        platformSecondSalePercentages[_tokenId] = _platformSecondSalePercentage;
        // emit an event to notify that the platform percent for this token has changed
        emit PlatformSalePercentageUpdated(_tokenId, _platformFirstSalePercentage, _platformSecondSalePercentage);
    }


    // Allows the platform to change the minimum percent increase for incoming bids
    function updateMinimumBidIncreasePercent(uint256 _minBidIncreasePercent) external onlyPlatform {
        require((_minBidIncreasePercent > 0) && (_minBidIncreasePercent <= 50), "Bid increases must be within 0-50%");
        // set the new bid increase percent
        minBidIncreasePercent = _minBidIncreasePercent;
    }


    function updateMaximumAuctionPeriod(uint256 _maxPeriod, uint256 _maxPrepTime) external onlyPlatform {
        maximumAuctionPeriod = _maxPeriod;
        maximumAuctionPreparingTime = _maxPrepTime;
    }


    // --- deprecated ---
    // Allow the platform to update a token's URI if it's not locked yet (for fixing tokens post mint process)
    // function updateTokenURI(uint256 tokenId, string tokenURI) external onlyPlatform {
    //     // ensure that this token exists 
    //     require(_exists(tokenId));
    //     // ensure that the URI for this token is not locked yet
    //     require(tokenURILocked[tokenId] == false);
    //     // update the token URI
    //     super._setTokenURI(tokenId, tokenURI);
    // }


    // --- deprecated ---
    // Locks a token's URI from being updated
    // function lockTokenURI(uint256 tokenId) external onlyPlatform {
    //     // ensure that this token exists
    //     require(_exists(tokenId));
    //     // lock this token's URI from being changed
    //     tokenURILocked[tokenId] = true;
    // }


    // Allows platform to change the percentage that artists receive on secondary sales
    function updateArtistSecondSalePercentage(uint256 _artistSecondSalePercentage) external onlyPlatform {
        // update the percentage that artists get on secondary sales
        artistSecondSalePercentage = _artistSecondSalePercentage;
        // emit an event to notify that the artist second sale percent has updated
        emit ArtistSecondSalePercentUpdated(artistSecondSalePercentage);
    }


    function setupControlToken
    (
        uint256 _controlTokenId, 
        string _controlTokenURI,
        int256[] _leverMinValues,
        int256[] _leverMaxValues,
        int256 _numAllowedUpdates,
        address[] _additionalCollaborators
    ) 
        external 
    {
        // Hard cap the number of levers a single control token can have
        require(_leverMinValues.length <= 500, "Too many control levers.");
        // Hard cap the number of collaborators a single control token can have
        require(_additionalCollaborators.length <= 50, "Too many collaborators.");
        // check that a control token exists for this token id
        require(controlTokenMapping[_controlTokenId].exists, "No control token found");
        // ensure that this token is not setup yet
        require(controlTokenMapping[_controlTokenId].isSetup == false, "Already setup");
        // ensure that only the control token artist is attempting this mint
        require(uniqueTokenCreators[_controlTokenId][0] == msg.sender, "Must be control token artist");
        // enforce that the length of all the array lengths are equal
        require(_leverMinValues.length == _leverMaxValues.length, "Values array mismatch");
        // require the number of allowed updates to be infinite (-1) or some finite number
        require((_numAllowedUpdates == -1) || (_numAllowedUpdates > 0), "Invalid allowed updates");
        // mint the control token here
        super._safeMint(msg.sender, _controlTokenId);
        // set token URI
        super._setTokenURI(_controlTokenId, _controlTokenURI);        
        // create the control token
        controlTokenMapping[_controlTokenId] = ControlToken(_leverMinValues.length, _numAllowedUpdates, true, true);
        // create the control token levers now
        for (uint256 k = 0; k < _leverMinValues.length; k++) {
            // enforce that maxValue is greater than or equal to minValue
            require(_leverMaxValues[k] >= _leverMinValues[k], "Max val must >= min");
            // add the lever to this token
            controlTokenMapping[_controlTokenId].levers[k] = ControlLever(_leverMinValues[k],
                _leverMaxValues[k], _leverMinValues[k], true);
        }
        // the control token artist can optionally specify additional collaborators on this layer
        for (uint256 i = 0; i < _additionalCollaborators.length; i++) {
            // can't provide burn address as collaborator
            require(_additionalCollaborators[i] != address(0));

            uniqueTokenCreators[_controlTokenId].push(_additionalCollaborators[i]);
        }
    }


    function mintArtwork
    (
        uint256 _masterTokenId, 
        string _artworkTokenURI, 
        address[] _controlTokenArtists
    )
        external 
    {
        require(creatorWhitelist[_masterTokenId].creator == msg.sender, "not on the whitelist!");
        require(creatorWhitelist[_masterTokenId].layerCount == _controlTokenArtists.length, "mismatch layer count!");
        // Can't mint a token with ID 0 anymore
        require(_masterTokenId > 0);
        // Mint the token that represents ownership of the entire artwork    
        super._safeMint(msg.sender, _masterTokenId);
        // set the token URI for this art
        super._setTokenURI(_masterTokenId, _artworkTokenURI);
        // track the msg.sender address as the artist address for future royalties
        uniqueTokenCreators[_masterTokenId].push(msg.sender);
        // iterate through all control token URIs (1 for each control token)
        for (uint256 i = 0; i < _controlTokenArtists.length; i++) {
            // determine the tokenID for this control token
            uint256 controlTokenId = _masterTokenId + i + 1;
            // add this control token artist to the unique creator list for that control token
            uniqueTokenCreators[controlTokenId].push(_controlTokenArtists[i]);
            // stub in an existing control token so exists is true
            controlTokenMapping[controlTokenId] = ControlToken(0, 0, true, false);

            // Layer control tokens use the same royalty percentage as the master token
            platformFirstSalePercentages[controlTokenId] = platformFirstSalePercentages[_masterTokenId];

            platformSecondSalePercentages[controlTokenId] = platformSecondSalePercentages[_masterTokenId];
        }
    }


    // Allow the owner to sell a piece through auction
    function openAuction(uint256 _tokenId, uint256 _prepTime, uint256 _auctionTime, uint256 _reservePrice) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not the owner!");
        require(pendingBids[_tokenId].exists == false, "On sale!");
        require(sellingState[_tokenId].auctionEndTime < now, "There is an existing auction");
        require(_prepTime <= maximumAuctionPreparingTime, "Exceed max preparing time");
        require(_auctionTime <= maximumAuctionPeriod, "Exceed max auction time!");
        sellingState[_tokenId].auctionStartTime = now + _prepTime;
        sellingState[_tokenId].auctionEndTime = sellingState[_tokenId].auctionStartTime + _auctionTime;
        sellingState[_tokenId].reservePrice = _reservePrice;
        emit AuctionCreated(_tokenId, sellingState[_tokenId].auctionStartTime, sellingState[_tokenId].auctionEndTime);
    }


    // Allow the owner to cancel the auction before it goes live
    function cancelAuction(uint256 _tokenId) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not the owner!");
        require(sellingState[_tokenId].auctionStartTime >= now, "Too late!");
        sellingState[_tokenId].auctionEndTime = 0;
        sellingState[_tokenId].auctionStartTime = 0;
        emit AuctionCancelled(_tokenId);
    }


    // Bidder functions
    function bid(uint256 _tokenId) external payable {
        // cannot equal, don't allow bids of 0
        require(msg.value >= sellingState[_tokenId].reservePrice && msg.value > 0);
        // Check for auction expiring time
        require(sellingState[_tokenId].auctionStartTime <= now, "Auction hasn't started!");
        // Check for auction expiring time
        require(sellingState[_tokenId].auctionEndTime >= now, "Auction expired!");
        // don't let owners/approved bid on their own tokens
        require(_isApprovedOrOwner(msg.sender, _tokenId) == false);
        // check if there's a high bid
        if (pendingBids[_tokenId].exists) {
            // enforce that this bid is higher by at least the minimum required percent increase
            require(msg.value >= (pendingBids[_tokenId].amount.mul(minBidIncreasePercent.add(100)).div(100)), "Bid must increase by min %");
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
        // attempt to withdraw the bid
        _withdrawBid(_tokenId);        
    }


    function _withdrawBid(uint256 _tokenId) internal {
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
        require(sellingState[_tokenId].auctionEndTime <= now);
        // check if there's a bid to accept
        require(pendingBids[_tokenId].exists);
        // process the sale
        onTokenSold(_tokenId, pendingBids[_tokenId].amount, pendingBids[_tokenId].bidder);
    }


    // Allows owner of a control token to set an immediate buy price. Set to 0 to reset.
    function makeBuyPrice(uint256 _tokenId, uint256 _buyPrice) external {
        // check if sender is owner/approved of token        
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        // set the buy price
        sellingState[_tokenId].buyPrice = _buyPrice;
        // emit event
        emit BuyPriceSet(_tokenId, _buyPrice);
    }


    function setSellingState(uint256 _tokenId, uint256 _buyPrice, uint256 _startTime, uint256 _endTime, uint256 _reservePrice) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not the owner!");
        require(pendingBids[_tokenId].exists == false, "On sale!");
        require(sellingState[_tokenId].auctionStartTime > now || sellingState[_tokenId].auctionEndTime < now, "There is an existing auction");
        require(now + maximumAuctionPreparingTime >= _startTime, "Exceed max preparing time");
        require(_startTime + maximumAuctionPeriod >= _endTime, "Exceed max auction time!");
        // set the buy price
        sellingState[_tokenId].buyPrice = _buyPrice;
        sellingState[_tokenId].auctionStartTime = _startTime;
        sellingState[_tokenId].auctionEndTime = _endTime;
        sellingState[_tokenId].reservePrice = _reservePrice;
        // emit event
        emit BuyPriceSet(_tokenId, _buyPrice);
        emit AuctionCreated(_tokenId, sellingState[_tokenId].auctionStartTime, sellingState[_tokenId].auctionEndTime);
    }


    // Buy the artwork for the currently set price
    // Allows the buyer to specify an expected remaining uses they'll accept
    function takeBuyPrice(uint256 _tokenId, int256 _expectedRemainingUpdates) external payable {
        // don't let owners/approved buy their own tokens
        require(_isApprovedOrOwner(msg.sender, _tokenId) == false);
        // get the sale amount
        uint256 saleAmount = sellingState[_tokenId].buyPrice;
        // check that there is a buy price
        require(saleAmount > 0);
        // check that the buyer sent exact amount to purchase
        require(msg.value == saleAmount);
        // if this is a control token
        if (controlTokenMapping[_tokenId].exists) {
            // ensure that the remaining uses on the token is equal to what buyer expects
            require(controlTokenMapping[_tokenId].numRemainingUpdates >= _expectedRemainingUpdates);
        }
        // Return all highest bidder's money
        if (pendingBids[_tokenId].exists) {
            // Return bid amount back to bidder
            safeFundsTransfer(pendingBids[_tokenId].bidder, pendingBids[_tokenId].amount);
            // clear highest bid
            pendingBids[_tokenId] = PendingBid(address(0), 0, false);
        }
        onTokenSold(_tokenId, saleAmount, msg.sender);
    }


    // Take an amount and distribute it evenly amongst a list of creator addresses
    function distributeFundsToCreators(uint256 _amount, address[] memory _creators) private {
        uint256 creatorShare = _amount.div(_creators.length);

        for (uint256 i = 0; i < _creators.length; i++) {
            safeFundsTransfer(_creators[i], creatorShare);
        }
    }


    // When a token is sold via list price or bid. Distributes the sale amount to the unique token creators and transfer
    // the token to the new owner
    function onTokenSold(uint256 _tokenId, uint256 saleAmount, address to) private {
        // if the first sale already happened, then give the artist + platform the secondary royalty percentage
        if (tokenDidHaveFirstSale[_tokenId]) {
            // give platform its secondary sale percentage
            uint256 platformAmount = saleAmount.mul(platformSecondSalePercentages[_tokenId]).div(100);
            safeFundsTransfer(platformAddress, platformAmount);
            // distribute the creator royalty amongst the creators (all artists involved for a base token, sole artist creator for layer )
            uint256 creatorAmount = saleAmount.mul(artistSecondSalePercentage).div(100);
            distributeFundsToCreators(creatorAmount, uniqueTokenCreators[_tokenId]);
            // cast the owner to a payable address
            address payableOwner = address(uint160(ownerOf(_tokenId)));
            // transfer the remaining amount to the owner of the token
            safeFundsTransfer(payableOwner, saleAmount.sub(platformAmount).sub(creatorAmount));
        } else {
            tokenDidHaveFirstSale[_tokenId] = true;
            // give platform its first sale percentage
            platformAmount = saleAmount.mul(platformFirstSalePercentages[_tokenId]).div(100);
            safeFundsTransfer(platformAddress, platformAmount);
            // this is a token first sale, so distribute the remaining funds to the unique token creators of this token
            // (if it's a base token it will be all the unique creators, if it's a control token it will be that single artist)                      
            distributeFundsToCreators(saleAmount.sub(platformAmount), uniqueTokenCreators[_tokenId]);
        }
        // clear highest bid
        pendingBids[_tokenId] = PendingBid(address(0), 0, false);
        // clear selling state
        sellingState[_tokenId] = SellingState(0, 0, 0, 0);
        // Transfer token to msg.sender
        _transferFrom(ownerOf(_tokenId), to, _tokenId);
        // Emit event
        emit TokenSale(_tokenId, saleAmount, to);
    }


    // return the number of times that a control token can be used
    function getNumRemainingControlUpdates(uint256 controlTokenId) external view returns (int256) {
        require(controlTokenMapping[controlTokenId].exists, "Token does not exist.");

        return controlTokenMapping[controlTokenId].numRemainingUpdates;
    }


    // return the min, max, and current value of a control lever
    function getControlToken(uint256 controlTokenId) external view returns(int256[] memory) {
        require(controlTokenMapping[controlTokenId].exists, "Token does not exist.");

        ControlToken storage controlToken = controlTokenMapping[controlTokenId];

        int256[] memory returnValues = new int256[](controlToken.numControlLevers.mul(3));
        uint256 returnValIndex = 0;

        // iterate through all the control levers for this control token
        for (uint256 i = 0; i < controlToken.numControlLevers; i++) {
            returnValues[returnValIndex] = controlToken.levers[i].minValue;
            returnValIndex = returnValIndex.add(1);

            returnValues[returnValIndex] = controlToken.levers[i].maxValue;
            returnValIndex = returnValIndex.add(1);

            returnValues[returnValIndex] = controlToken.levers[i].currentValue;
            returnValIndex = returnValIndex.add(1);
        }

        return returnValues;
    }
    
    
    function getTokenOnSale() external view returns(uint256[] memory tokenIds) {
        uint256 tokenCount = 0;
        for(uint256 i = 1; i < expectedTokenSupply; ++i) {
            if(sellingState[i].buyPrice > 0 || sellingState[i].auctionEndTime > now) {
                ++tokenCount;
            }
        }
        tokenIds = new uint256[](tokenCount);
        tokenCount = 0;
        for(i = 1; i < expectedTokenSupply; ++i) {
            if(sellingState[i].buyPrice > 0 || sellingState[i].auctionEndTime > now) {
                tokenIds[tokenCount] = i;
                ++tokenCount;
            }
        }
    }


    // anyone can grant permission to another address to control a specific token on their behalf. Set to Address(0) to reset.
    function grantControlPermission(uint256 tokenId, address permissioned) external {
        permissionedControllers[msg.sender][tokenId] = permissioned;

        emit PermissionUpdated(tokenId, msg.sender, permissioned);
    }


    // Allows owner (or permissioned user) of a control token to update its lever values
    // Optionally accept a payment to increase speed of rendering priority
    function useControlToken(uint256 controlTokenId, uint256[] leverIds, int256[] newValues) external payable {
        // check if sender is owner/approved of token OR if they're a permissioned controller for the token owner      
        require(_isApprovedOrOwner(msg.sender, controlTokenId) || (permissionedControllers[ownerOf(controlTokenId)][controlTokenId] == msg.sender),
            "Owner or permissioned only");
        // check if control exists
        require(controlTokenMapping[controlTokenId].exists, "Token does not exist.");
        // get the control token reference
        ControlToken storage controlToken = controlTokenMapping[controlTokenId];
        // check that number of uses for control token is either infinite or is positive
        require((controlToken.numRemainingUpdates == -1) || (controlToken.numRemainingUpdates > 0), "No more updates allowed");        
        // collect the previous lever values for the event emit below
        int256[] memory previousValues = new int256[](newValues.length);

        for (uint256 i = 0; i < leverIds.length; i++) {
            // get the control lever
            ControlLever storage lever = controlTokenMapping[controlTokenId].levers[leverIds[i]];

            // Enforce that the new value is valid        
            require((newValues[i] >= lever.minValue) && (newValues[i] <= lever.maxValue), "Invalid val");

            // Enforce that the new value is different
            require(newValues[i] != lever.currentValue, "Must provide different val");

            // grab previous value for the event emit
            previousValues[i] = lever.currentValue;

            // Update token current value
            lever.currentValue = newValues[i];    
        }

        // if there's a payment then send it to the platform (for higher priority updates)
        if (msg.value > 0) {
            safeFundsTransfer(platformAddress, msg.value);
        }

        // if this control token is finite in its uses
        if (controlToken.numRemainingUpdates > 0) {
            // decrease it down by 1
            controlToken.numRemainingUpdates = controlToken.numRemainingUpdates - 1;

            // since we used one of those updates, withdraw any existing bid for this token if exists
            if (pendingBids[controlTokenId].exists) {
                _withdrawBid(controlTokenId);
            }
        }

        // emit event
        emit ControlLeverUpdated(controlTokenId, msg.value, controlToken.numRemainingUpdates, leverIds, previousValues, newValues);
    }


    // Allows a user to withdraw all failed transaction credits
    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0);
        require(address(this).balance >= amount);

        failedTransferCredits[msg.sender] = 0;

        bool successfulWithdraw = msg.sender.call.value(amount)("");
        require(successfulWithdraw);
    }


    // Safely transfer funds and if fail then store that amount as credits for a later pull
    function safeFundsTransfer(address recipient, uint256 amount) internal {
        // attempt to send the funds to the recipient
        bool success = recipient.call.value(amount).gas(2300)("");
        // if it failed, update their credit balance so they can pull it later
        if (success == false) {
            failedTransferCredits[recipient] = failedTransferCredits[recipient].add(amount);
        }
    }

    
    // override transferFrom function
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(pendingBids[tokenId].exists == false, "Pending bid!");
        require(sellingState[tokenId].auctionEndTime == 0, "token on sale!");
        sellingState[tokenId] = SellingState(0, 0, 0, 0);
        super.transferFrom(from, to, tokenId);
    }
}
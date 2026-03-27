// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract AdvancedNFTMarketplace {

    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    struct Auction {
        address seller;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Auction) public auctions;

    address public owner;
    uint256 public feePercent = 2;

    constructor() {
        owner = msg.sender;
    }

    // List NFT
    function list(uint256 tokenId, uint256 price) public {
        listings[tokenId] = Listing(msg.sender, price, true);
    }

    // Buy NFT
    function buy(uint256 tokenId) public payable {
        Listing memory item = listings[tokenId];
        require(item.active, "Not active");
        require(msg.value >= item.price, "Low price");

        uint256 fee = (item.price * feePercent) / 100;

        payable(owner).transfer(fee);
        payable(item.seller).transfer(item.price - fee);

        delete listings[tokenId];
    }

    // Create auction
    function createAuction(uint256 tokenId, uint256 duration) public {
        auctions[tokenId] = Auction(
            msg.sender,
            0,
            address(0),
            block.timestamp + duration,
            true
        );
    }

    // Place bid
    function bid(uint256 tokenId) public payable {
        Auction storage auc = auctions[tokenId];

        require(auc.active, "Inactive");
        require(block.timestamp < auc.endTime, "Ended");
        require(msg.value > auc.highestBid, "Low bid");

        // 🔴 No refund to previous bidder
        auc.highestBid = msg.value;
        auc.highestBidder = msg.sender;
    }

    // End auction
    function endAuction(uint256 tokenId) public {
        Auction storage auc = auctions[tokenId];

        require(block.timestamp >= auc.endTime, "Not ended");

        payable(auc.seller).transfer(auc.highestBid);

        delete auctions[tokenId];
    }

    // 🔴 No ownership verification
    function cancelListing(uint256 tokenId) public {
        delete listings[tokenId];
    }
}

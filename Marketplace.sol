// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRegistry.sol";

/**
 * @title Marketplace
 * @dev A contract that allows players to list, sell, and buy game NFTs using LMT tokens.
 * This contract holds listed NFTs in escrow until they are sold or delisted.
 */
contract Marketplace is Ownable {
    IRegistry public immutable registry;

    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price; // in LMT tokens
    }

    // A unique identifier for each listing
    // keccak256(abi.encodePacked(nftContract, tokenId)) => Listing
    mapping(bytes32 => Listing) private _listings;

    // Fee percentage in basis points (e.g., 250 = 2.5%)
    uint256 public feePercentage;

    event ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemDelisted(
        address indexed nftContract,
        uint256 indexed tokenId
    );
    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );
    event FeeUpdated(uint256 newFeePercentage);


    constructor(address registryAddress, uint256 initialFeePercentage) Ownable(msg.sender) {
        registry = IRegistry(registryAddress);
        feePercentage = initialFeePercentage;
    }

    /**
     * @dev Lists an NFT for sale. The contract must be approved to transfer the NFT first.
     * The NFT is held in escrow by this contract.
     * @param nftContract The address of the NFT collection.
     * @param tokenId The ID of the token to list.
     * @param price The selling price in LMT tokens (with decimals).
     */
    function listItem(address nftContract, uint256 tokenId, uint256 price) external {
        require(price > 0, "Marketplace: Price must be greater than zero");
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Marketplace: You do not own this item");

        bytes32 listingId = _getListingId(nftContract, tokenId);
        require(_listings[listingId].price == 0, "Marketplace: Item is already listed");

        // Transfer NFT to this contract for escrow
        nft.transferFrom(msg.sender, address(this), tokenId);

        _listings[listingId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price
        });

        emit ItemListed(msg.sender, nftContract, tokenId, price);
    }

    /**
     * @dev Allows the original seller to delist their item.
     */
    function delistItem(address nftContract, uint256 tokenId) external {
        bytes32 listingId = _getListingId(nftContract, tokenId);
        Listing memory listing = _listings[listingId];
        
        require(listing.seller == msg.sender, "Marketplace: You are not the seller");

        delete _listings[listingId];

        IERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenId);

        emit ItemDelisted(nftContract, tokenId);
    }

    /**
     * @dev Buys a listed item. The buyer must first approve the marketplace to spend LMT.
     */
    function buyItem(address nftContract, uint256 tokenId) external {
        bytes32 listingId = _getListingId(nftContract, tokenId);
        Listing memory listing = _listings[listingId];
        require(listing.price > 0, "Marketplace: Item is not listed for sale");
        require(listing.seller != msg.sender, "Marketplace: You cannot buy your own item");

        IERC20 lmtToken = IERC20(registry.getAddress(registry.LMT_TOKEN()));
        
        uint256 fee = (listing.price * feePercentage) / 10000;
        uint256 sellerProceeds = listing.price - fee;

        delete _listings[listingId];

        // Transfer funds: Buyer -> Seller and Buyer -> This contract (for fees)
        lmtToken.transferFrom(msg.sender, listing.seller, sellerProceeds);
        if (fee > 0) {
            lmtToken.transferFrom(msg.sender, address(this), fee);
        }

        // Transfer NFT to buyer
        IERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenId);

        emit ItemSold(listing.seller, msg.sender, nftContract, tokenId, listing.price);
    }

    /**
     * @dev Allows the contract owner to withdraw collected fees.
     */
    function withdrawFees() external onlyOwner {
        IERC20 lmtToken = IERC20(registry.getAddress(registry.LMT_TOKEN()));
        uint256 balance = lmtToken.balanceOf(address(this));
        if (balance > 0) {
            lmtToken.transfer(owner(), balance);
        }
    }

    /**
     * @dev Allows the owner to update the transaction fee percentage.
     * @param newFeePercentage The new fee in basis points (e.g., 300 for 3.0%).
     */
    function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
        // Max fee of 20% (2000 basis points) to prevent accidental high fees
        require(newFeePercentage <= 2000, "Marketplace: Fee cannot exceed 20%");
        feePercentage = newFeePercentage;
        emit FeeUpdated(newFeePercentage);
    }

    /**
     * @dev Generates a unique ID for a listing.
     */
    function _getListingId(address nftContract, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftContract, tokenId));
    }

    /**
     * @dev Returns the details of a specific listing.
     */
    function getListing(address nftContract, uint256 tokenId) external view returns (Listing memory) {
        bytes32 listingId = _getListingId(nftContract, tokenId);
        return _listings[listingId];
    }
}
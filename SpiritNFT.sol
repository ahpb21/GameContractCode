// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SpiritNFT
 * @dev Represents a unique "灵岚" (Spirit) partner in the game.
 * Each Spirit is a unique ERC721 token.
 *
 * Minting is restricted to the contract owner, intended to be a specific
 * game logic contract (e.g., for hatching or purification rituals).
 */
contract SpiritNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;

    /**
     * @dev Sets the name, symbol, and initial owner.
     */
    constructor(string memory baseTokenURI) ERC721("Linglan Mirage Spirit", "LMS") Ownable(msg.sender) {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev The base URI for all token metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Allows the owner to update the base URI for all tokens.
     */
    function setBaseURI(string memory newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    /**
     * @dev Mints a new Spirit NFT and assigns it to `to`.
     * Can only be called by the contract owner.
     * @param to The address to receive the newly minted NFT.
     * @return The ID of the newly minted token.
     */
    function safeMint(address to) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }
}
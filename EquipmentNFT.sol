// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title EquipmentNFT
 * @dev Represents a unique piece of equipment in the game "灵岚魅影".
 * Each piece of equipment is a unique ERC721 token.
 *
 * Minting is restricted to the contract owner, which will eventually be the
 * DungeonController contract, to ensure items are only created from gameplay.
 *
 * Metadata is handled via a base URI, pointing to a directory on IPFS
 * where each token's JSON metadata is stored.
 */
contract EquipmentNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;

    /**
     * @dev Sets the name, symbol, and initial owner.
     */
    constructor(string memory baseTokenURI) ERC721("Linglan Mirage Equipment", "LME") Ownable(msg.sender) {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev The base URI for all token metadata.
     * The final URI for a token is (_baseTokenURI + tokenId).
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Allows the owner to update the base URI for all tokens.
     * Useful for migrating metadata storage or updating the folder.
     * @param newBaseTokenURI The new base URI.
     */
    function setBaseURI(string memory newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    /**
     * @dev Mints a new piece of equipment NFT and assigns it to `to`.
     * Increments the token ID counter automatically.
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
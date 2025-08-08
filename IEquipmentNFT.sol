// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IEquipmentNFT
 * @dev Interface for the EquipmentNFT contract.
 */
interface IEquipmentNFT {
    /**
     * @dev Mints a new piece of equipment NFT and assigns it to `to`.
     */
    function safeMint(address to) external returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256);
}
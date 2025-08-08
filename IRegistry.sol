// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IRegistry
 * @dev Interface for the central Registry contract.
 */
interface IRegistry {
    // --- Public constants for contract names ---
    // It's useful to have these here for any contract that uses the registry.
    function LMT_TOKEN() external pure returns (bytes32);
    function EQUIPMENT_NFT() external pure returns (bytes32);
    function SPIRIT_NFT() external pure returns (bytes32);
    function CHARACTER_MANAGER() external pure returns (bytes32);
    function DUNGEON_CONTROLLER() external pure returns (bytes32);
    function MARKETPLACE() external pure returns (bytes32);
    function ITEM_ATTRIBUTES() external pure returns (bytes32);

    /**
     * @dev Retrieves the address for a given contract name.
     */
    function getAddress(bytes32 name) external view returns (address);
}
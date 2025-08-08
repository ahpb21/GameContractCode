// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICharacterManager
 * @dev Interface for the CharacterManager contract.
 */
interface ICharacterManager {
    /**
     * @dev Grants experience points to a player.
     */
    function grantExperience(address player, uint256 amount) external;

    /**
     * @dev NEW: Gets the core combat stats for a player.
     */
    function getCharacterStats(address player) external view returns (uint256 maxHP, uint256 attack, uint256 defense);
}
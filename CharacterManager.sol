// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IItemAttributes.sol";
import {IEquipmentNFT} from "./interfaces/IEquipmentNFT.sol";

/**
 * @title CharacterManager (Enhanced with Equipment System)
 * @dev Manages player characters, including their base stats and equipped items.
 * It calculates total combat stats by combining base stats with equipped item stats.
 */
contract CharacterManager is Ownable {
    IRegistry public immutable registry;

    // --- MODIFIED: Added combat stats to the Character struct ---
    struct Character {
        uint64 level;
        uint256 experience;
        uint256 createdAt;
        // --- NEW STATS ---
        uint256 maxHP;
        uint256 attack;
        uint256 defense;
    }

    // <<< NEW: Equipment slots mapping for each player
    // We define slots as: 0=上衣, 1=胸甲, 2=腰带, 3=护腿, 4=战靴, etc.
    mapping(address => mapping(uint8 => uint256)) public equippedItems;

    mapping(address => Character) private _characters;

    event CharacterCreated(address indexed player, uint256 timestamp);
    event ExperienceGranted(address indexed player, uint256 amount);
    event LevelUp(address indexed player, uint256 newLevel);

    modifier onlyGameLogic() {
        address dungeonController = registry.getAddress(
            registry.DUNGEON_CONTROLLER()
        );
        require(
            msg.sender == dungeonController,
            "CharacterManager: Caller is not an authorized game logic contract"
        );
        _;
    }

    constructor(address registryAddress) Ownable(msg.sender) {
        registry = IRegistry(registryAddress);
    }

    /**
     * @dev Creates a new character profile with initial stats.
     */
    function createCharacter() public {
        require(
            _characters[msg.sender].createdAt == 0,
            "CharacterManager: Character already exists"
        );

        // --- MODIFIED: Initialize new stats upon creation ---
        _characters[msg.sender] = Character({
            level: 1,
            experience: 0,
            createdAt: block.timestamp,
            // --- NEW: Set base stats for a level 1 character ---
            maxHP: 100,
            attack: 15,
            defense: 5
        });

        emit CharacterCreated(msg.sender, block.timestamp);
    }

    // --- (grantExperience function remains unchanged) ---
    function grantExperience(address player, uint256 amount)
        public
        onlyGameLogic
    {
        require(
            _characters[player].createdAt != 0,
            "CharacterManager: Player does not have a character"
        );
        Character storage character = _characters[player];
        character.experience += amount;
        emit ExperienceGranted(player, amount);
        uint256 requiredExp = getExperienceForLevel(character.level);
        while (character.experience >= requiredExp) {
            character.level++;
            // --- NEW: Improve stats on level up! ---
            character.maxHP += 10;
            character.attack += 2;
            character.defense += 1;
            character.experience -= requiredExp;
            emit LevelUp(player, character.level);
            requiredExp = getExperienceForLevel(character.level);
        }
    }

    // <<< NEW: Function to equip an item ---
    /**
     * @dev Equips an item (NFT) into a specified slot.
     * @param tokenId The ID of the equipment NFT to wear.
     * @param slot The equipment slot to place the item in.
     */
    function equip(uint256 tokenId, uint8 slot) external {
        IEquipmentNFT equipmentNFT = IEquipmentNFT(
            registry.getAddress(registry.EQUIPMENT_NFT())
        );
        // 1. Verify the player owns the NFT they are trying to equip.
        require(
            equipmentNFT.ownerOf(tokenId) == msg.sender,
            "You do not own this item."
        );

        // (Optional) Add logic here to check if the slot is valid for the item type.

        // 2. If an item is already in the slot, unequip it first.
        if (equippedItems[msg.sender][slot] != 0) {
            // In a full system, you might transfer this back to a conceptual "bag".
            // For now, we just clear the slot.
        }

        // 3. Equip the new item.
        equippedItems[msg.sender][slot] = tokenId;
    }

    // <<< NEW: Function to unequip an item ---
    function unequip(uint8 slot) external {
        // Simple unequip, just clears the slot.
        equippedItems[msg.sender][slot] = 0;
    }

    /**
     * @dev Returns the full character data struct for a given player.
     */
    function getCharacter(address player)
        public
        view
        returns (Character memory)
    {
        return _characters[player];
    }

    // <<< MODIFIED: getCharacterStats is now the "Total Stats Calculator" ---
    /**
     * @dev Calculates and returns the total combat stats for a player,
     * including base stats and all bonuses from equipped items.
     */
    function getCharacterStats(address player) public view returns (uint256, uint256, uint256) {
        Character memory character = _characters[player];
        require(character.createdAt != 0, "Character does not exist");

        IItemAttributes itemAttributes = IItemAttributes(registry.getAddress(registry.ITEM_ATTRIBUTES()));

        // Start with the character's base stats
        uint256 totalHP = character.maxHP;
        uint256 totalAttack = character.attack;
        uint256 totalDefense = character.defense;

        // Loop through equipment slots and add stats
        // For simplicity, we are checking 5 armor slots (0-4)
        for (uint8 i = 0; i < 5; i++) {
            uint256 equippedTokenId = equippedItems[player][i];
            if (equippedTokenId != 0) {
                ItemAttributes.Stats memory stats = itemAttributes.itemStats(equippedTokenId);
                totalHP += stats.maxHP;
                totalAttack += stats.attack;
                totalDefense += stats.defense;
                // You can add logic for other stats like strength, spirit, etc. here
            }
        }

        return (totalHP, totalAttack, totalDefense);
    }

    function getExperienceForLevel(uint64 level) public pure returns (uint256) {
        return 100 * (uint256(level)**2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ItemAttributes
 * @dev This contract serves as an on-chain database to store the core combat
 * attributes of each equipment NFT's tokenId.
 * It is designed to be written to only by a trusted contract (the DungeonController).
 */
contract ItemAttributes is Ownable {

    // Defines the core combat stats for an item.
    struct Stats {
        uint256 attack;
        uint256 defense;
        uint256 maxHP;
        uint256 maxMP;
        uint256 strength; // 力量
        uint256 intelligence; // 智力
        uint256 stamina; // 体力
        uint256 spirit; // 精神
    }

    // Mapping from the EquipmentNFT's tokenId to its on-chain stats.
    mapping(uint256 => Stats) public itemStats;

    // The address of the DungeonController, which is authorized to record stats.
    address public statSetter;

    event StatsRecorded(uint256 indexed tokenId);
    event StatSetterUpdated(address indexed newSetter);

    constructor(address initialOwner, address initialStatSetter) Ownable(initialOwner) {
        statSetter = initialStatSetter;
        emit StatSetterUpdated(initialStatSetter);
    }
    
    /**
     * @dev Records or updates the stats for a given tokenId.
     * Can only be called by the authorized statSetter (DungeonController).
     * @param tokenId The ID of the NFT in the EquipmentNFT contract.
     * @param stats The Stats struct containing the item's attributes.
     */
    function recordStats(uint256 tokenId, Stats calldata stats) external {
        require(msg.sender == statSetter, "ItemAttributes: Caller is not the authorized stat setter");
        itemStats[tokenId] = stats;
        emit StatsRecorded(tokenId);
    }

    /**
     * @dev Allows the contract owner to update the address of the statSetter.
     * Useful for when the DungeonController contract is upgraded.
     */
    function setStatSetter(address newSetter) external onlyOwner {
        require(newSetter != address(0), "Cannot set to zero address");
        statSetter = newSetter;
        emit StatSetterUpdated(newSetter);
    }
}
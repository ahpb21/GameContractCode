// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// <<< DELETED: No longer need to import Ownable from OpenZeppelin
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Import V2.5 Plus base contract and client library
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// Import local interfaces
import "./interfaces/IRegistry.sol";
import "./interfaces/ICharacterManager.sol";
import "./interfaces/IEquipmentNFT.sol";
import "./interfaces/ILMT_Token.sol";
import "./interfaces/IItemAttributes.sol";

// <<< MODIFIED: Removed Ownable from the inheritance list
contract DungeonController is VRFConsumerBaseV2Plus {
    // --- (All structs, mappings, events, and state variables remain the same) ---
    struct EnemyStats {
        string name;
        uint256 maxHP;
        uint256 baseAttack;
        uint256 baseDefense;
        uint256 experienceReward;
    }
    struct Battle {
        address player;
        uint256 enemyId;
        uint256 playerCurrentHP;
        uint256 enemyCurrentHP;
        uint256 turn;
        bool battleEnded;
    }

    struct LootItem {
        uint256 templateId; // 定义掉落的装备
        uint32 chance; // 定义掉落的几率 概率用万分之来表示
    }

    // <<< NEW: Mapping from an enemyId to its array of possible loot items
    // 核心掉落表数据库，键是敌人的ID，值是一个包含该敌人所有可能掉落物品的数组。
    mapping(uint256 => LootItem[]) public lootTables;

    mapping(uint256 => EnemyStats) private _enemies;
    mapping(address => Battle) public activeBattles;
    // ---
    mapping(uint256 => ItemAttributes.Stats) private _itemTemplates;
    event ItemTemplateAdded(uint256 indexed templateId);
    // ---

    event EnemyAdded(uint256 indexed enemyId, string name);
    event BattleStarted(address indexed player, uint256 indexed enemyId);
    event BattleTurnTaken(
        uint256 indexed requestId,
        address indexed player,
        uint256 turn
    );
    event BattleWon(
        address indexed player,
        uint256 experience,
        uint256 tokenId
    );
    event BattleLost(address indexed player);
    IRegistry public immutable registry;
    uint256 private s_subscriptionId;
    bytes32 private immutable _keyHash;
    uint32 private immutable _callbackGasLimit = 250000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 2;
    mapping(uint256 => address) public s_requestToPlayer;

    // <<< MODIFIED: Removed Ownable(msg.sender) from the constructor
    constructor(
        address registryAddress,
        address vrfCoordinator,
        uint256 subscriptionId,
        bytes32 keyHash
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        // Note: Ownable() call is gone
        registry = IRegistry(registryAddress);
        s_subscriptionId = subscriptionId;
        _keyHash = keyHash;
    }

    // --- (All other functions: addEnemy, startBattle, takePlayerTurn, fulfillRandomWords, setSubscriptionId remain the same) ---
    // Note: The 'onlyOwner' modifier still works because it is provided by VRFConsumerBaseV2Plus's parent contracts.
    function addEnemy(
        uint256 enemyId,
        string memory name,
        uint256 maxHP,
        uint256 baseAttack,
        uint256 baseDefense,
        uint256 exp
    ) external onlyOwner {
        require(maxHP > 0, "HP must be greater than 0");
        _enemies[enemyId] = EnemyStats(
            name,
            maxHP,
            baseAttack,
            baseDefense,
            exp
        );
        emit EnemyAdded(enemyId, name);
    }

    function startBattle(uint256 enemyId) external {
        require(
            activeBattles[msg.sender].battleEnded == true ||
                activeBattles[msg.sender].player == address(0),
            "Player is already in a battle."
        );
        require(
            _enemies[enemyId].maxHP > 0,
            "Enemy with this ID does not exist."
        );
        ICharacterManager characterManager = ICharacterManager(
            registry.getAddress(registry.CHARACTER_MANAGER())
        );
        (uint256 playerInitialHP, , ) = characterManager.getCharacterStats(
            msg.sender
        );
        require(playerInitialHP > 0, "Player must have HP to battle.");
        activeBattles[msg.sender] = Battle({
            player: msg.sender,
            enemyId: enemyId,
            playerCurrentHP: playerInitialHP,
            enemyCurrentHP: _enemies[enemyId].maxHP,
            turn: 1,
            battleEnded: false
        });
        emit BattleStarted(msg.sender, enemyId);
    }

    function takePlayerTurn() external {
        Battle storage currentBattle = activeBattles[msg.sender];
        require(currentBattle.player == msg.sender, "You are not in a battle.");
        require(!currentBattle.battleEnded, "This battle has already ended.");
        VRFV2PlusClient.RandomWordsRequest memory req;
        req.keyHash = _keyHash;
        req.subId = s_subscriptionId;
        req.requestConfirmations = REQUEST_CONFIRMATIONS;
        req.callbackGasLimit = _callbackGasLimit;
        req.numWords = NUM_WORDS;
        req.extraArgs = VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
        );
        uint256 requestId = s_vrfCoordinator.requestRandomWords(req);
        s_requestToPlayer[requestId] = msg.sender;
        emit BattleTurnTaken(requestId, msg.sender, currentBattle.turn);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        // --- 1. Setup and Validation ---
        address player = s_requestToPlayer[requestId];
        require(player != address(0), "Invalid request ID");
        delete s_requestToPlayer[requestId]; // Clean up immediately

        Battle storage currentBattle = activeBattles[player];
        EnemyStats storage currentEnemy = _enemies[currentBattle.enemyId];
        ICharacterManager characterManager = ICharacterManager(
            registry.getAddress(registry.CHARACTER_MANAGER())
        );

        // --- 2. Player's Attack Phase ---
        (
            ,
            uint256 playerBaseAttack,
            uint256 playerBaseDefense
        ) = characterManager.getCharacterStats(player);
        uint256 playerDamageRoll = (randomWords[0] % 8) + 1;
        uint256 totalPlayerDamage = playerBaseAttack + playerDamageRoll;
        totalPlayerDamage = totalPlayerDamage > currentEnemy.baseDefense
            ? totalPlayerDamage - currentEnemy.baseDefense
            : 1;

        if (totalPlayerDamage >= currentBattle.enemyCurrentHP) {
            currentBattle.enemyCurrentHP = 0;
        } else {
            currentBattle.enemyCurrentHP -= totalPlayerDamage;
        }

        // --- 3. Check for Player Victory ---
        if (currentBattle.enemyCurrentHP == 0) {
            currentBattle.battleEnded = true;
            characterManager.grantExperience(
                player,
                currentEnemy.experienceReward
            );

            // <<< MODIFIED: Call the new helper function for loot drops
            uint256 newTokenId = _handleLootDrop(
                player,
                randomWords[1],
                currentBattle.enemyId
            );

            emit BattleWon(player, currentEnemy.experienceReward, newTokenId);
            return;
        }

        // --- 4. Enemy's Attack Phase ---
        uint256 enemyDamageRoll = (randomWords[1] % 6) + 1;
        uint256 totalEnemyDamage = currentEnemy.baseAttack + enemyDamageRoll;
        totalEnemyDamage = totalEnemyDamage > playerBaseDefense
            ? totalEnemyDamage - playerBaseDefense
            : 1;

        if (totalEnemyDamage >= currentBattle.playerCurrentHP) {
            currentBattle.playerCurrentHP = 0;
        } else {
            currentBattle.playerCurrentHP -= totalEnemyDamage;
        }

        // --- 5. Check for Player Defeat ---
        if (currentBattle.playerCurrentHP == 0) {
            currentBattle.battleEnded = true;
            emit BattleLost(player);
            return;
        }

        // --- 6. Continue Battle ---
        currentBattle.turn++;
    }

    // <<< NEW: Private helper function to handle loot logic
    /**
     * @dev Internal function to process loot drops for a given enemy.
     * @param player The address of the winning player.
     * @param lootRoll A random number (0-9999) to determine the drop.
     * @param enemyId The ID of the defeated enemy.
     * @return tokenId The ID of the minted token, or 0 if no loot dropped.
     */
    function _handleLootDrop(
        address player,
        uint256 lootRoll,
        uint256 enemyId
    ) private returns (uint256) {
        uint256 roll = lootRoll % 10000;
        uint256 cumulativeChance = 0;
        LootItem[] storage table = lootTables[enemyId];

        for (uint256 i = 0; i < table.length; i++) {
            cumulativeChance += table[i].chance;
            if (roll < cumulativeChance) {
                uint256 templateIdToDrop = table[i].templateId;
                ItemAttributes.Stats memory statsToRecord = _itemTemplates[
                    templateIdToDrop
                ];

                IEquipmentNFT equipmentNFT = IEquipmentNFT(
                    registry.getAddress(registry.EQUIPMENT_NFT())
                );
                uint256 newTokenId = equipmentNFT.safeMint(player);

                IItemAttributes itemAttributes = IItemAttributes(
                    registry.getAddress(registry.ITEM_ATTRIBUTES())
                );
                itemAttributes.recordStats(newTokenId, statsToRecord);

                return newTokenId;
            }
        }
        return 0; // No loot dropped
    }

    function setSubscriptionId(uint256 subscriptionId) external onlyOwner {
        s_subscriptionId = subscriptionId;
    }

    /**
     * @dev Adds or updates an item template that can be dropped as loot.
     * @param templateId A unique ID for the item template (e.g., 101 for '迷幻星云上衣').
     * @param stats The core combat stats for this item template.
     */
    function addItemTemplate(
        uint256 templateId,
        ItemAttributes.Stats calldata stats
    ) external onlyOwner {
        _itemTemplates[templateId] = stats;
        emit ItemTemplateAdded(templateId);
    }

    // <<< NEW: Admin function to add a loot item to an enemy's drop table
    function addLootToTable(
        uint256 enemyId,
        uint256 templateId,
        uint32 chance
    ) external onlyOwner {
        require(_enemies[enemyId].maxHP > 0, "Enemy does not exist.");
        require(
            chance > 0 && chance <= 10000,
            "Chance must be between 1 and 10000."
        );

        lootTables[enemyId].push(
            LootItem({templateId: templateId, chance: chance})
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Registry
 * @dev A central on-chain address book for all contracts in the "灵岚魅影" ecosystem.
 * This allows for an upgradeable architecture where contract dependencies can be
 * updated without redeploying the contracts that depend on them.
 *
 * Only the owner (initially the deployer, later a DAO) can update contract addresses.
 */
contract Registry is Ownable {
    // --- Public constants for contract names (gas efficient) ---
    bytes32 public constant LMT_TOKEN = keccak256(abi.encodePacked("LMT_TOKEN"));
    bytes32 public constant EQUIPMENT_NFT = keccak256(abi.encodePacked("EQUIPMENT_NFT"));
    bytes32 public constant SPIRIT_NFT = keccak256(abi.encodePacked("SPIRIT_NFT"));
    bytes32 public constant CHARACTER_MANAGER = keccak256(abi.encodePacked("CHARACTER_MANAGER"));
    bytes32 public constant DUNGEON_CONTROLLER = keccak256(abi.encodePacked("DUNGEON_CONTROLLER"));
    bytes32 public constant MARKETPLACE = keccak256(abi.encodePacked("MARKETPLACE"));
    bytes32 public constant ITEM_ATTRIBUTES = keccak256(abi.encodePacked("ITEM_ATTRIBUTES"));
    // Add other contract names here as the system grows.

    mapping(bytes32 => address) private _addresses;

    event AddressSet(bytes32 indexed name, address indexed newAddress);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Sets or updates the address for a given contract name.
     * Only callable by the owner.
     * @param name The name of the contract (use the public constants).
     * @param contractAddress The address of the deployed contract.
     */
    function setAddress(bytes32 name, address contractAddress) public onlyOwner {
        require(contractAddress != address(0), "Registry: Cannot set to zero address");
        _addresses[name] = contractAddress;
        emit AddressSet(name, contractAddress);
    }

    /**
     * @dev Retrieves the address for a given contract name.
     * @param name The name of the contract.
     * @return The address of the contract.
     */
    function getAddress(bytes32 name) public view returns (address) {
        address contractAddress = _addresses[name];
        require(contractAddress != address(0), "Registry: Address not found for this name");
        return contractAddress;
    }
}
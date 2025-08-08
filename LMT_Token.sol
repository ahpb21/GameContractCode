// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LMT_Token
 * @dev This is the ERC20 token contract for the game "灵岚魅影" (Phantom of Linglan).
 * Token Name: Linglan & Mirage Token
 * Token Symbol: LMT
 *
 * It uses OpenZeppelin's ERC20 and Ownable contracts.
 * The contract deployer will be the initial owner and will receive the initial supply.
 * The owner has the ability to mint new tokens, a power that should be transferred
 * to a governance or staking contract in the future.
 */
contract LMT_Token is ERC20, Ownable {

    /**
     * @dev Sets the name, symbol for the token and mints the initial supply.
     * The entire initial supply is minted to the address that deploys the contract.
     */
    constructor(uint256 initialSupply) ERC20("Linglan & Mirage Token", "LMT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    /**
     * @dev Creates `amount` new tokens and assigns them to `to`.
     * This function can only be called by the contract owner.
     * This is intended for future use by governance or other core game contracts
     * to distribute rewards.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
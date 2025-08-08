// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ILMT_Token
 * @dev Extends the standard IERC20 interface for our game token.
 * We are using OpenZeppelin's IERC20 for a complete and standard interface.
 */
interface ILMT_Token is IERC20 {
    // You can add custom functions here if your token has them.
    // For now, the standard IERC20 is sufficient.
}
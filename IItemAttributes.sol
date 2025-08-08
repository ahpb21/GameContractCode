// interfaces/IItemAttributes.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ItemAttributes} from "../ItemAttributes.sol";

interface IItemAttributes {
    function recordStats(uint256 tokenId, ItemAttributes.Stats calldata stats) external;
    function itemStats(uint256 tokenId) external view returns (ItemAttributes.Stats memory);
}
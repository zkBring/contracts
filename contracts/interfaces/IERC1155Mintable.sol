// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IERC1155Mintable {
  function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}

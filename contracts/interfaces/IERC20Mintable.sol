// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IERC20Mintable {
  function mint(address to, uint256 amount) external;
}

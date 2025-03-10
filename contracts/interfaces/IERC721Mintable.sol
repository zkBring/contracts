// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IERC721Mintable {
  function safeMint(address to) external;
}

// SPDX-License-Identifier: MIT
/* pragma solidity ^0.8.17; */

/* import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol"; */
/* import "openzeppelin-solidity/contracts/access/AccessControl.sol"; */
/* import "../interfaces/IERC1155Mintable.sol"; */

/* contract ERC1155Mock is ERC1155, AccessControl, IERC1155Mintable { */
/*     bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE"); */
/*     bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); */

/*     constructor() ERC1155("") { */
/*         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); */
/*         _setupRole(URI_SETTER_ROLE, msg.sender); */
/*         _setupRole(MINTER_ROLE, msg.sender); */
/*     } */

/*     function setURI(string memory newuri) public { */
/*       require(hasRole(URI_SETTER_ROLE, msg.sender), "Not authorized"); */
/*         _setURI(newuri); */
/*     } */

/*     function mint(address account, uint256 id, uint256 amount, bytes memory data) */
/*         public override */
/*     { */
/*       require(hasRole(MINTER_ROLE, msg.sender), "Not authorized");       */
/*         _mint(account, id, amount, data); */
/*     } */

/*     function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) */
/*         public */
/*     { */
/*       require(hasRole(MINTER_ROLE, msg.sender), "Not authorized"); */
/*         _mintBatch(to, ids, amounts, data); */
/*     } */
/* } */

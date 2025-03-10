/* // SPDX-License-Identifier: MIT */
/* pragma solidity ^0.8.17; */

/* import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; */
/* import "openzeppelin-solidity/contracts/access/AccessControl.sol"; */
/* import "../interfaces/IERC20Mintable.sol"; */

/* contract ERC20Mock is ERC20, AccessControl, IERC20Mintable { */
/*     bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); */

/*     constructor() ERC20("LinkdropMockERC20", "LMT") { */
/*         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); */
/*         _setupRole(MINTER_ROLE, msg.sender); */
/*     } */

/*     function mint(address to, uint256 amount) public  override  { */
/*       require(hasRole(MINTER_ROLE, msg.sender), "Not authorized"); */
/*       _mint(to, amount); */
/*     } */
/* } */

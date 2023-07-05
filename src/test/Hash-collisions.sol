// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*
Demo: abi.encodePacked() Hash Collisions

Using abi.encodePacked() with multiple variable length arguments can, 
in certain situations, lead to a hash collision.

Hash functions are designed to be unique for each input, 
but collisions can still occur due to limitations in the hash function's size or the sheer number of possible inputs. 
This is a known issue mentioned:
https://docs.soliditylang.org/en/v0.8.17/abi-spec.html?highlight=collisions#non-standard-packed-mode


In deposit function allows users to deposit Ether into the contract based on two string inputs: _string1 and _string2. 
The contract uses the keccak256 function to generate a unique hash by concatenating these two strings.

If two different combinations of _string1 and _string2 produce the same hash value, a hash collision will occur. 
The code does not handle this scenario properly and allows the second depositor to overwrite the previous deposit.

Mitigation  
use of abi.encode() instead of abi.encodePacked()

REF:
https://docs.soliditylang.org/en/v0.8.17/abi-spec.html?highlight=collisions#non-standard-packed-mode
https://swcregistry.io/docs/SWC-133
https://github.com/sherlock-audit/2022-10-nftport-judging/issues/118
*/

contract ContractTest is Test {
        HashCollisionBug HashCollisionBugContract;
 
function setUp() public { 
        HashCollisionBugContract = new HashCollisionBug();
    }

function testRounding_error() public {

    emit log_named_bytes32("(AAA,BBB) Hash",HashCollisionBugContract.createHash("AAA","BBB"));
    HashCollisionBugContract.deposit{value: 1 ether}("AAA","BBB");

    emit log_named_bytes32("(AA,ABBB) Hash",HashCollisionBugContract.createHash("AA","ABBB"));
    HashCollisionBugContract.deposit{value: 1 ether}("AA","ABBB"); //Hash collision detected
    }
    
    receive() payable external{}
}
contract HashCollisionBug {
    mapping(bytes32 => uint256) public balances;

    function createHash(string memory _string1, string memory _string2) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_string1, _string2));
    }

    function deposit(string memory _string1, string memory _string2) external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        bytes32 hash = createHash(_string1, _string2);
        // createHash(AAA, BBB) -> AAABBB
        // createHash(AA, ABBB) -> AAABBB
        // Check if the hash already exists in the balances mapping
        require(balances[hash] == 0, "Hash collision detected");

        balances[hash] = msg.value;
    }
}

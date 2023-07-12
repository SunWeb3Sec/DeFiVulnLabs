// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*

Demo: Incorrect use of payable.transfer()
uses Solidity’s transfer() when transferring ETH to the recipients. 
This has some notable shortcomings when the recipient is a smart contract, 
which can render ETH impossible to transfer.
Specifically, the transfer will inevitably fail when the smart contract:
    1.does not implement a payable fallback function, or
    2.implements a payable fallback function which would incur more than 2300 gas units, or
    3.implements a payable fallback function incurring less than 2300 gas units but is called through a proxy that raises the call’s gas usage above 2300.

Mitigation  
Using call with its returned boolean checked in combination with re-entrancy guard is highly recommended.

REF:
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

function testTransfer() public {
    SimpleBankContract.deposit{value: 1 ether}();  
    assertEq(SimpleBankContract.getBalance(),1 ether);
    SimpleBankContract.withdraw(1 ether);  
    }

 
function testCall() public {
    FixedSimpleBankContract.deposit{value: 1 ether}();  
    assertEq(FixedSimpleBankContract.getBalance(),1 ether);
    FixedSimpleBankContract.withdraw(1 ether);  
    }

    receive() payable external{
        //just a example for out of gas
        SimpleBankContract.deposit{value: 1 ether}();  
    }
}

contract SimpleBank {
    mapping (address => uint) private balances;

    function deposit() public payable{
         balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
contract FixedSimpleBank {
    mapping (address => uint) private balances;

    function deposit() public payable{
         balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{ value: amount }('');
        require(success, " Transfer of ETH Failed");
    }
}

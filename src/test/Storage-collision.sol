// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/*
Name: Storage Collision Vulnerability

Description:
The vulnerability is that both the Proxy and Logic contracts use the same storage slot (slot 0) to store important variables,
namely the implementation address in the Proxy contract and the GuestAddress in the Logic contract. 
Since the Proxy contract is using the delegatecall method to interact with the Logic contract, 
they share the same storage. If the foo function is called,
it overwrites the implementation address in the Proxy contract, which results in an unexpected behavior.

Mitigation:
One approach to mitigating this issue is to design the storage layout of the proxy and logic contracts to be consistent with each other.

REF:
https://blog.openzeppelin.com/proxy-patterns
*/

contract ContractTest is Test {
    Logic LogicContract;
    Proxy ProxyContract;

    function testStorageCollision() public {
        LogicContract = new Logic();
        ProxyContract = new Proxy(address(LogicContract));

        console.log(
            "Current implementation contract address:",
            ProxyContract.implementation()
        );
        ProxyContract.testcollision();
        console.log(
            "overwritten slot0 implementation contract address:",
            ProxyContract.implementation()
        );
        console.log("Exploit completed");
    }

    receive() external payable {}
}

contract Proxy {
    address public implementation; //slot0

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function testcollision() public {
        bool success;
        (success, ) = implementation.delegatecall(
            abi.encodeWithSignature("foo(address)", address(this))
        );
    }
}

contract Logic {
    address public GuestAddress; //slot0

    constructor() {
        GuestAddress = address(0x0);
    }

    function foo(address _addr) public {
        GuestAddress = _addr;
    }
}

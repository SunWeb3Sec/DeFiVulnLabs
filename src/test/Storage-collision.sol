// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
 
contract ContractTest is Test {
        Logic LogicContract;
        Proxy ProxyContract;

function testStorageCollision() public {

    LogicContract = new Logic();
    ProxyContract = new Proxy(address(LogicContract));

    console.log("Current implementation contract address:",ProxyContract.implementation());
    ProxyContract.testcollision();
    console.log("overwrited slot0 implementation contract address:",ProxyContract.implementation());
    console.log("Exploit completed");
    }
    receive() payable external{}
}

contract Proxy {
    address public implementation;  //slot0

    constructor (address _implementation) public {
        implementation = _implementation;
    }

    function testcollision() public {
        implementation.delegatecall(
            abi.encodeWithSignature("foo(address)",address(this))
        );
    }
}

contract Logic {
    address public GuestAddress; //slot0
    
    constructor () public {
        GuestAddress = address(0x0);
    }

    function foo(address _addr) public {
        GuestAddress = _addr;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "forge-std/Test.sol";

contract ContractTest is Test {
        Vault VaultContract;

function testReadprivatedata() public {
        VaultContract = new Vault(123456789);
        bytes32 leet = vm.load(address(VaultContract), bytes32(uint256(0)));
        emit log_uint(uint256(leet)); 

    // users in slot 1 - length of array
    // starting from slot hash(1) - array elements
    // slot where array element is stored = keccak256(slot)) + (index * elementSize)
    // where slot = 1 and elementSize = 2 (1 (uint) +  1 (bytes32))
        bytes32 user = vm.load(address(VaultContract), VaultContract.getArrayLocation(1,1,1));
        emit log_uint(uint256(user)); 
    }
}

contract Vault {
    // slot 0
    uint256 private password;
    constructor(uint256  _password) {
        password = _password;
        User memory user = User({id: 0, password: bytes32(_password)});
        users.push(user);
        idToUser[0] = user;
    }

    struct User {
        uint id;
        bytes32 password;
    }

    // slot 1
    User[] public users;
    // slot 2
    mapping(uint => User) public idToUser; 
    function getArrayLocation(
        uint slot,
        uint index,
        uint elementSize
    ) public pure returns (bytes32) {
        uint256 a= uint(keccak256(abi.encodePacked(slot))) + (index * elementSize);
        return bytes32(a);
    }
}

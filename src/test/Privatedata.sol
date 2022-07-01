// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "forge-std/Test.sol";

contract ContractTest is Test {
        Vault VaultContract;

function testReadprivatedata() public {
        VaultContract = new Vault(123456789);
        bytes32 leet = vm.load(address(VaultContract), bytes32(uint256(0)));
        emit log_uint(uint256(leet)); 
        
    }
}


contract Vault {
    // slot 0
    uint256 private password;
    constructor(uint256  _password) {
        password = _password;
    }
}

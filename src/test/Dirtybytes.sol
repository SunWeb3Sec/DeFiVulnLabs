// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
// the issue is fixed in 0.8.15

import "forge-std/Test.sol";

/*
Name: Dirtybytes in > Solidity 0.8.15
    "description": "Copying ``bytes`` arrays from memory or calldata to storage is done in chunks of 32 bytes even if the length is not a multiple of 32. 
    Thereby, extra bytes past the end of the array may be copied from calldata or memory to storage. 
    These dirty bytes may then become observable after a ``.push()`` without arguments to the bytes array in storage,
    i.e. such a push will not result in a zero value at the end of the array as expected. 
    This bug only affects the legacy code generation pipeline, the new code generation pipeline via IR is not affected."
    
    "link": https://blog.soliditylang.org/2022/06/15/dirty-bytes-array-to-storage-bug/
    "fixed": 0.8.15

*/

contract ContractTest is Test {
    Dirtybytes Dirtybytesontract;

    function testDirtybytes() public {
        Dirtybytesontract = new Dirtybytes();
        emit log_named_bytes(
            "Array element in h() not being zero::",
            Dirtybytesontract.h()
        );
        console.log(
            "Such that the byte after the 63 bytes allocated below will be 0x02."
        );
    }
}

contract Dirtybytes {
    event ev(uint[], uint);
    bytes s;

    constructor() {
        // The following event emission involves writing to temporary memory at the current location
        // of the free memory pointer. Several other operations (e.g. certain keccak256 calls) will
        // use temporary memory in a similar manner.
        // In this particular case, the length of the passed array will be written to temporary memory
        // exactly such that the byte after the 63 bytes allocated below will be 0x02. This dirty byte
        // will then be written to storage during the assignment and become visible with the push in ``h``.
        emit ev(new uint[](2), 0);
        bytes memory m = new bytes(63);
        s = m;
    }

    function h() external returns (bytes memory) {
        s.push();
        return s;
    }
}

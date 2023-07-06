// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*
Demo: Struct Deletion Oversight: Incomplete struct deletion leaves residual data. 
If you delete a struct containing a mapping, the mapping won't be deleted.

The bug arises because Solidity's delete keyword does not reset the storage to its 
initial state but rather performs a partial reset. 
When delete  myStructs[structId] is called, 
it only resets the id at mappingId to its default value 0, 
but the other flags in the mapping remain unchanged. Therefore,
if the struct is deleted without deleting the mapping inside, 
the remaining flags will persist in storage.

Mitigation  
To fix this bug, you should delete the mapping inside the struct before deleting the struct itself.

REF:
https://docs.soliditylang.org/en/develop/types.html
*/

contract ContractTest is Test {
        StructDeletionBug StructDeletionBugContract;
        FixedStructDeletion FixedStructDeletionContract;
 
function setUp() public { 
        StructDeletionBugContract = new StructDeletionBug();
        FixedStructDeletionContract = new FixedStructDeletion();
    }

function testStructDeletion() public {
    StructDeletionBugContract.addStruct(10,10);
    StructDeletionBugContract.getStruct(10,10);
    StructDeletionBugContract.deleteStruct(10);
    StructDeletionBugContract.getStruct(10,10);
    }


function testFixedStructDeletion() public {
    FixedStructDeletionContract.addStruct(10,10);
    FixedStructDeletionContract.getStruct(10,10);
    FixedStructDeletionContract.deleteStruct(10);
    FixedStructDeletionContract.getStruct(10,10);
    }

    receive() payable external{}
}

contract StructDeletionBug {
    struct MyStruct {
        uint256 id;
        mapping(uint256 => bool) flags;
    }

    mapping(uint256 => MyStruct) public myStructs;

    function addStruct(uint256 structId, uint256 flagKeys) public {
        MyStruct storage newStruct = myStructs[structId];
        newStruct.id = structId;
        newStruct.flags[flagKeys] = true;

    }

    function getStruct(uint256 structId, uint256 flagKeys) public view returns (uint256, bool ) {
        MyStruct storage myStruct = myStructs[structId];
        bool keys = myStruct.flags[flagKeys] ;
        return (myStruct.id, keys);
    }

    function deleteStruct(uint256 structId) public {
        MyStruct storage myStruct = myStructs[structId];
        delete myStructs[structId];
    }
}

contract FixedStructDeletion {
    struct MyStruct {
        uint256 id;
        mapping(uint256 => bool) flags;
    }

    mapping(uint256 => MyStruct) public myStructs;

    function addStruct(uint256 structId, uint256 flagKeys) public {
        MyStruct storage newStruct = myStructs[structId];
        newStruct.id = structId;
        newStruct.flags[flagKeys] = true;

    }

    function getStruct(uint256 structId, uint256 flagKeys) public view returns (uint256, bool ) {
        MyStruct storage myStruct = myStructs[structId];
        bool keys = myStruct.flags[flagKeys] ;
        return (myStruct.id, keys);
    }

    function deleteStruct(uint256 structId) public {
        MyStruct storage myStruct = myStructs[structId];
				// Check if all flags are deleted, then delete the mapping
        for (uint256 i = 0; i < 15; i++) {
            delete myStruct.flags[i];
        }
        delete myStructs[structId];
    }
}

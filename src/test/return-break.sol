 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*
Demo: Use of return in inner loop iteration leads to unintended termination. 

BankContractBug's addBanks function exhibits an incorrect usage of the return statement within a loop iteration, 
resulting in unintended termination of the loop. The return statement is placed inside the inner loop, 
causing premature exit from the function before completing the iteration over all bank addresses. 

use break instead of return

Mitigation  
Use break instead of return

REF:
https://github.com/code-423n4/2022-03-lifinance-findings/issues/34
https://solidity-by-example.org/loop/

*/

contract ContractTest is Test {
        BankContractBug BankContractBugContract;
        FixedBank FixedBankContract;
 
function setUp() public { 
        BankContractBugContract = new BankContractBug();
        FixedBankContract = new FixedBank();
    }

function testReturnBug() public {
        address[] memory bankAddresses = new address[](3);
        string[] memory bankNames = new string[](3);
        
        // Bank account 1
        bankAddresses[0] = address(1);
        bankNames[0] = "ABC Bank";
        
        // Bank account 2
        bankAddresses[1] = address(2);
        bankNames[1] = "XYZ Bank";
        
        // Bank account 3
        bankAddresses[2] = address(3);
        bankNames[2] = "Global Bank";

        BankContractBugContract.addBanks(bankAddresses,bankNames);
        BankContractBugContract.getBankCount();
    }

function testBreak() public {
        address[] memory bankAddresses = new address[](3);
        string[] memory bankNames = new string[](3);
        
        // Bank account 1
        bankAddresses[0] = address(1);
        bankNames[0] = "ABC Bank";
        
        // Bank account 2
        bankAddresses[1] = address(2);
        bankNames[1] = "XYZ Bank";
        
        // Bank account 3
        bankAddresses[2] = address(3);
        bankNames[2] = "Global Bank";

        FixedBankContract.addBanks(bankAddresses,bankNames);
        FixedBankContract.getBankCount();
    }

    receive() payable external{}
}

contract BankContractBug {
    struct Bank {
        address bankAddress;
        string bankName;
    }
    
    Bank[] public banks;
    
    function addBanks(address[] memory bankAddresses, string[] memory bankNames) public {
        require(bankAddresses.length == bankNames.length, "Input arrays must have the same length.");

       for (uint i = 0; i < bankAddresses.length; i++) {
         if (bankAddresses[i] == address(0)) {
            continue;
        }
        
            for (uint i = 0; i < bankAddresses.length; i++) {
                banks.push(Bank(bankAddresses[i], bankNames[i]));
                return;
        }
    }
    }
    function getBankCount() public view returns (uint) {
        return banks.length;
    }
}

contract FixedBank {
    struct Bank {
        address bankAddress;
        string bankName;
    }
    
    Bank[] public banks;
    
    function addBanks(address[] memory bankAddresses, string[] memory bankNames) public {
        require(bankAddresses.length == bankNames.length, "Input arrays must have the same length.");

       for (uint i = 0; i < bankAddresses.length; i++) {
         if (bankAddresses[i] == address(0)) {
            continue;
        }
         
            for (uint i = 0; i < bankAddresses.length; i++) {
                banks.push(Bank(bankAddresses[i], bankNames[i]));
                break; // Correct usage of break to terminate the inner loop
        }
    }
    }
    function getBankCount() public view returns (uint) {
        return banks.length;
    }
}

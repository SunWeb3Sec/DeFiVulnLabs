// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/*
Name: txGasPrice manipulation

Description:
Manipulation of the txGasPrice value, which can result in unintended consequences and potential financial losses.

In the calculateTotalFee function, the total fee is calculated by multiplying gasUsed + GAS_OVERHEAD_NATIVE with txGasPrice. 
The issue is that the txGasPrice value can be manipulated by an attacker, potentially leading to an inflated fee calculation.

Mitigation:  
To address this vulnerability, it is recommended to implement safeguards such as using a gas oracle to obtain the average gas price from a trusted source. 

Test:
forge test --contracts src/test/gas-price.sol  -vvvv --gas-price 200000000000000

REF:
https://twitter.com/1nf0s3cpt/status/1678268482641870849
https://github.com/solodit/solodit_content/blob/main/reports/ZachObront/2023-03-21-Alligator.md
https://github.com/solodit/solodit_content/blob/main/reports/Trust%20Security/2023-05-15-Brahma.md
https://blog.pessimistic.io/ethereum-alarm-clock-exploit-final-thoughts-21334987c331
*/

contract ContractTest is Test {
    GasReimbursement GasReimbursementContract;

    function setUp() public {
        GasReimbursementContract = new GasReimbursement();
        vm.deal(address(GasReimbursementContract), 100 ether);
    }

    function testGasRefund() public {
        uint balanceBefore = address(this).balance;
        GasReimbursementContract.executeTransfer(address(this));
        uint balanceAfter = address(this).balance - tx.gasprice; // --gas-price 200000000000000
        console.log("Profit", balanceAfter - balanceBefore);
    }

    receive() external payable {}
}

contract GasReimbursement {
    uint public gasUsed = 100000; // Assume gas used is 100,000
    uint public GAS_OVERHEAD_NATIVE = 500; // Assume native token gas overhead is 500

    // uint public txGasPrice = 20000000000;  // Assume transaction gas price is 20 gwei

    function calculateTotalFee() public view returns (uint) {
        uint256 totalFee = (gasUsed + GAS_OVERHEAD_NATIVE) * tx.gasprice;
        return totalFee;
    }

    function executeTransfer(address recipient) public {
        uint256 totalFee = calculateTotalFee();
        _nativeTransferExec(recipient, totalFee);
    }

    function _nativeTransferExec(address recipient, uint256 amount) internal {
        payable(recipient).transfer(amount);
    }
}

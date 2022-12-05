// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

contract ContractTest is Test {
        Miscalculation MiscalculationContract;
        Calculation CalculationContract;

function testMiscalculation() public {
 
    MiscalculationContract = new Miscalculation();
    console.log("Perform Miscalculation Contract");
    console.log("Scenario: DeFi store 10% off now, Then we buy 1 item price: $80.");
    console.log("Subtract the discount, get the sale price:",MiscalculationContract.price(80,90));
    console.log("Solidity doesn't do decimals, so dividing before multiplying will round to zero. 0.8*90=0");
    console.log("---------------------------------------------------------");
    CalculationContract = new Calculation();
    console.log("Perform Correct calculation Contract");
    console.log("Scenario: DeFi store 10% off now, Then we buy 1 item price: $80.");
    console.log("Subtract  the discount, get the sale price:",CalculationContract.price(80,90));
    console.log("Multiply before dividing is correct . 80*90/100=72");
    }

}


contract Miscalculation { 
    function price(uint256 price, uint256 discount) public pure returns (uint256) {
        return price / 100 * discount;  // wrong calculation
    }
}

contract Calculation { 
    function price(uint256 price, uint256 discount) public pure returns (uint256) {
        return price  *  discount / 100;  // correct calculation
    }
}

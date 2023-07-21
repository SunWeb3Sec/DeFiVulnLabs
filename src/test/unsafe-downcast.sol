// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
// Import the SafeCast library
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/*

Demo:
Unsafe downcasting
Downcasting from a larger integer type to a smaller one without checks can lead to unexpected behavior 
if the value of the larger integer is outside the range of the smaller one.

Mitigation  
Make sure consistent uint256, or use openzepplin safeCasting.

REF:
https://github.com/code-423n4/2022-12-escher-findings/issues/369
https://github.com/sherlock-audit/2022-10-union-finance-judging/issues/96
*/

contract ContractTest is Test {
    SimpleBank SimpleBankContract;
    FixedSimpleBank FixedSimpleBankContract;

    function setUp() public {
        SimpleBankContract = new SimpleBank();
        FixedSimpleBankContract = new FixedSimpleBank();
    }

    function testUnsafeDowncast() public {
        SimpleBankContract.deposit(257); //overflowed

        console.log(
            "balance of SimpleBankContract:",
            SimpleBankContract.getBalance()
        );

        // balance is 1, because of overflowed
        assertEq(SimpleBankContract.getBalance(), 1);
    }

    function testsafeDowncast() public {
        vm.expectRevert("SafeCast: value doesn't fit in 8 bits");
        FixedSimpleBankContract.deposit(257); //revert
    }

    receive() external payable {}
}

contract SimpleBank {
    mapping(address => uint) private balances;

    function deposit(uint256 amount) public {
        // Here's the unsafe downcast. If the `amount` is greater than type(uint8).max
        // (which is 255), then only the least significant 8 bits are stored in balance.
        // This could lead to unexpected results due to overflow.
        uint8 balance = uint8(amount);

        // store the balance
        balances[msg.sender] = balance;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}

contract FixedSimpleBank {
    using SafeCast for uint256; // Use SafeCast for uint256

    mapping(address => uint) private balances;

    function deposit(uint256 _amount) public {
        // Use the `toUint8()` function from `SafeCast` to safely downcast `amount`.
        // If `amount` is greater than `type(uint8).max`, it will revert.
        // or keep the same uint256 with amount.
        uint8 amount = _amount.toUint8(); // or keep uint256

        // Store the balance
        balances[msg.sender] = amount;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}

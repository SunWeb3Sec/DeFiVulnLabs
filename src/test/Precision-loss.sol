// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*
Demo:
Precision Loss - rounding down to zero

Support all the ERC20 tokens, as those tokens may have different decimal places. 
For example, USDT and USDC have 6 decimals. So, in the calculations, one must be careful.

Mitigation  
Avoid any situation that if the numerator is smaller than the denominator, the result will be zero.
Rounding down related issues can be avoided in many ways:
    1.Using libraries for rounding up/down as expected
    2.Requiring result is not zero or denominator is <= numerator
    3.Refactor operations for avoiding first dividing then multiplying, when first dividing then multiplying, precision lost is amplified


REF:
https://github.com/sherlock-audit/2023-02-surge-judging/issues/244
https://github.com/sherlock-audit/2023-02-surge-judging/issues/122
https://dacian.me/precision-loss-errors#heading-rounding-down-to-zero
*/

contract ContractTest is Test {
        SimplePool SimplePoolContract;
 
function setUp() public { 
        SimplePoolContract = new SimplePool();
    }

function testRounding_error() public {

    SimplePoolContract.getCurrentReward();

    }
    
    receive() payable external{}
}

contract SimplePool {
    uint public totalDebt;
    uint public lastAccrueInterestTime;
    uint public loanTokenBalance;

    constructor() {
        totalDebt = 10000e6; //debt token is USDC and has 6 digit decimals.
        lastAccrueInterestTime = block.timestamp - 1  ;
        loanTokenBalance = 500e18;
    }

    function getCurrentReward() public view returns (uint _reward) {
        // Get the time passed since the last interest accrual
        uint _timeDelta = block.timestamp - lastAccrueInterestTime; //_timeDelta=1

        // If the time passed is 0, return 0 reward
        if (_timeDelta == 0) return 0;

        // Calculate the supplied value
        uint _supplied = totalDebt + loanTokenBalance;
        //console.log(_supplied);
        // Calculate the reward
        uint _reward = (totalDebt * _timeDelta) / (365 days * 1e18);
        console.log("Current reward",_reward);


        // 31536000 is the number of seconds in a year
        // 365 days * 1e18 = 31_536_000_000_000_000_000_000_000
        //_totalDebt * _timeDelta / 31_536_000_000_000_000_000_000_000 
        // 10_000_000_000 * 1 / 31_536_000_000_000_000_000_000_000 // -> 0
        return _reward;
    }
}

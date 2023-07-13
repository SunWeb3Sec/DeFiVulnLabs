// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
/*
Demo: Missing Check for Self-Transfer Allows Funds to be Lost

The vulnerability in the code stems from the absence of a check to prevent self-transfers. 
This oversight allows the transfer function to erroneously transfer funds to the same address. 
Consequently, funds are lost as the code fails to deduct the transferred amount from the sender's balance.
This vulnerability undermines the correctness of fund transfers within the contract and poses a risk 
to the integrity of user balances.

 
Mitigation  
Add condition to prevent transfer between same addresses

REF:
https://github.com/code-423n4/2022-10-traderjoe-findings/issues/299
https://www.immunebytes.com/blog/bzxs-security-focused-relaunch-followed-by-a-hack-how/

*/

contract ContractTest is Test {
        SimpleBank VSimpleBankContract;
        FixedSimpleBank FixedSimpleBankContract;
 
function setUp() public { 
        VSimpleBankContract = new SimpleBank();
        FixedSimpleBankContract = new FixedSimpleBank();

    }

function testSelfTransfer() public {
        VSimpleBankContract.transfer(address(this),address(this),10000);
        VSimpleBankContract.transfer(address(this),address(this),10000);
        VSimpleBankContract.balanceOf(address(this));
        /*
        unchecked {
        _balances[_id][Alice] = 10000 - 10000;
        _balances[_id][Alice] = 10000 + 10000;
         total balance of [Alice] = 20000
        }
        */
    }

function testFixedSelfTransfer() public {
        FixedSimpleBankContract.transfer(address(this),address(this),10000);
    }


    receive() payable external{}
}

contract SimpleBank {
    mapping(address => uint256) private _balances;

    function balanceOf(address _account) public view virtual returns (uint256) {
        return _balances[_account];
    }

    function transfer(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        uint256 _fromBalance = _balances[_from];
        uint256 _toBalance = _balances[_to];

        unchecked {
            _balances[_from] = _fromBalance - _amount;
            _balances[_to] = _toBalance + _amount;
        }
    }
}

contract FixedSimpleBank {
    mapping(address => uint256) private _balances;

    function balanceOf(address _account) public view virtual returns (uint256) {
        return _balances[_account];
    }

    function transfer(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        //Mitigation
        require(_from != _to, "Cannot transfer funds to the same address.");

        uint256 _fromBalance = _balances[_from];
        uint256 _toBalance = _balances[_to];

        unchecked {
            _balances[_from] = _fromBalance - _amount;
            _balances[_to] = _toBalance + _amount;
        /*
        Another mitigation
        _balances[_id][_from] -= _amount;
        _balances[_id][_to] += _amount;
        */
        }
    }
}

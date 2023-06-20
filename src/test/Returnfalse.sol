// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*

Some tokens do not revert on failure, but instead return false (e.g. ZRX).

ZRX transfer return false:
    function transfer(address _to, uint _value) returns (bool) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

Mitigation:
Use OpenZeppelin’s SafeERC20 library and change transfer to safeTransfer.

*/

interface CheatCodes {
    function startPrank(address) external;
    function stopPrank() external;
    function createSelectFork(string calldata,uint256) external returns(uint256);
}

contract ContractTest is DSTest {
    using SafeERC20 for IERC20;
    IERC20 constant zrx = IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498);
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);


  function setUp() public {
    cheats.createSelectFork("mainnet", 16138254); 
  }
        
function testTransfer() public {
    cheats.startPrank(0xef0DCc839c1490cEbC7209BAa11f46cfe83805ab);
    zrx.transfer(address(this),123);  //return false, do not revert
    cheats.stopPrank();
    }

function testSafeTransfer() public {
    cheats.startPrank(0xef0DCc839c1490cEbC7209BAa11f46cfe83805ab);
    zrx.safeTransfer(address(this),123); // revert
    cheats.stopPrank();
    }

receive() payable external{}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*

EIP20 standard:
Returns a boolean value indicating whether the operation succeeded.
function transfer(address to, uint256 amount) external returns (bool);

USDT don't correctly implement the EIP20 standard, 
so calling these functions with the correct EIP20 function signatures will always revert.
function transfer(address to, uint256 value) external;

ERC20 transfer:
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

USDT transfer without a return value:
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        ...
        }
        Transfer(msg.sender, _to, sendAmount);
    }

Mitigation:
Use OpenZeppelin’s SafeERC20 library and change transfer to safeTransfer.

*/
interface USDT {
  function transfer(address to, uint256 value) external;

  function balanceOf(address account) external view returns (uint256);

  function approve(address spender, uint256 value) external;
}
interface CheatCodes {
    function startPrank(address) external;
    function stopPrank() external;
    function createSelectFork(string calldata,uint256) external returns(uint256);
}

contract ContractTest is DSTest {
    using SafeERC20 for IERC20;
    IERC20 constant usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);


  function setUp() public {
    cheats.createSelectFork("mainnet", 16138254); 
  }
        
function testTransfer() public {
    cheats.startPrank(0xef0DCc839c1490cEbC7209BAa11f46cfe83805ab);
    usdt.transfer(address(this),123);  //revert
    cheats.stopPrank();
    }

function testSafeTransfer() public {
    cheats.startPrank(0xef0DCc839c1490cEbC7209BAa11f46cfe83805ab);
    usdt.safeTransfer(address(this),123);
    cheats.stopPrank();
    }

receive() payable external{}

}

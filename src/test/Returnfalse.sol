// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

contract ContractTest is Test {
    using SafeERC20 for IERC20;
    IERC20 constant zrx = IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498);

    function setUp() public {
        vm.createSelectFork("mainnet", 16138254);
    }

    function testTransfer() public {
        vm.startPrank(0xef0DCc839c1490cEbC7209BAa11f46cfe83805ab);
        zrx.transfer(address(this), 123); //return false, do not revert
        vm.stopPrank();
    }

    function testSafeTransferFail() public {
        vm.startPrank(0xef0DCc839c1490cEbC7209BAa11f46cfe83805ab);

        // https://github.com/foundry-rs/foundry/issues/5367 can't vm.expectRevert
        // vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
        zrx.safeTransfer(address(this), 123); //revert

        vm.stopPrank();
    }

    receive() external payable {}
}

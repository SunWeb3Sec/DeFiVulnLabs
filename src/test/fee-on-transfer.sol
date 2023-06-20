// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*

Demo:
STA token had a deflationary model with transfer fee of 1% charged from a recipient.

VulnVault: Incompatability with deflationary / fee-on-transfer tokens

Mitigation  
Transfer the tokens first and compare pre-/after token balances to compute the actual deposited amount.

*/

contract ContractTest is Test {
        STA STAContract;
        VulnVault VulnVaultContract;
        Vault VaultContract;
function setUp() public { 

        STAContract = new STA();
        VulnVaultContract = new VulnVault(address(STAContract));
        VaultContract = new Vault(address(STAContract));
    }

function testVulnFeeOnTransfer() public {

    address alice = vm.addr(1);
    address bob = vm.addr(2);
    STAContract.balanceOf(address(this));
    STAContract.transfer(alice,1000000); 
    console.log("Alice's STA balance:", STAContract.balanceOf(alice));  // charge 1% fee
    vm.startPrank(alice);
    STAContract.approve(address(VulnVaultContract),type(uint256).max);
    VulnVaultContract.deposit(10000);
    //VulnVaultContract.getBalance(alice);

    console.log("Alice deposit 10000 STA, but Alice's STA balance in VulnVaultContract:",  VulnVaultContract.getBalance(alice));  // charge 1% fee
    assertEq(STAContract.balanceOf(address(VulnVaultContract)),VulnVaultContract.getBalance(alice));
    }


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
    }
    receive() payable external{}
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

abstract contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) internal {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract STA is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "Statera";
  string constant tokenSymbol = "STA";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 100000000000000000000000000;
  uint256 public basePercent = 100;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _issue(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function cut(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 cutValue = roundValue.mul(basePercent).div(10000);
    return cutValue;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }


  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
  }

  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _issue(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function destroy(uint256 amount) external {
    _destroy(msg.sender, amount);
  }

  function _destroy(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function destroyFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _destroy(account, amount);
  }
}

//vulnerable vault
contract VulnVault  {
    mapping(address => uint256) private balances;
    uint256 private fee;
    IERC20 private token;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");

        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }
}


//Mitigated vault
contract Vault  {
    mapping(address => uint256) private balances;
    uint256 private fee;
    IERC20 private token;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");

        uint256 balanceBefore = token.balanceOf(address(this));

        token.transferFrom(msg.sender, address(this), amount);

        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 actualDepositAmount = balanceAfter - balanceBefore;

        balances[msg.sender] += actualDepositAmount;
        emit Deposit(msg.sender, actualDepositAmount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }
}

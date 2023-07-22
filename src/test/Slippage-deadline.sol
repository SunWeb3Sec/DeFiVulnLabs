// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
Name: Slippage - Incorrect deadline & slippage amount

Description:
Slippage: Slippage is the difference between the expected price of a trade 
and the price at which the trade is executed. 
If hardcoded to 0, user will accept a minimum amount of 0 output tokens from the swap.

Deadline: The function sets the deadline to the maximum uint256 value, 
which means the transaction can be executed at any time.

If slippage is set to 0 and there is no deadline, 
users might potentially lose all their tokens.

Mitigation:
Allow the user to specify the slippage & deadline value themselves.

REF:
https://twitter.com/1nf0s3cpt/status/1676118132992405505
*/

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IWETH {
    function deposit() external payable;

    function approve(address guy, uint256 wad) external returns (bool);

    function withdraw(uint256 wad) external;
}

contract ContractTest is Test {
    address UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Router address on Ethereum Mainnet
    IWETH WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function setUp() public {
        vm.createSelectFork("mainnet", 17568400);
    }

    function testswapTokensWithMaxDeadline() external payable {
        WETH.approve(address(UNISWAP_ROUTER), type(uint256).max);
        WETH.deposit{value: 1 ether}();

        uint256 amountIn = 1 ether;
        uint256 amountOutMin = 0;
        //uint256 amountOutMin = 1867363899; //1867363899 INSUFFICIENT_OUTPUT_AMOUNT
        // Path for swapping ETH to USDT
        address[] memory path = new address[](2);
        path[0] = address(WETH); // WETH (Wrapped Ether)
        path[1] = USDT; // USDT (Tether)

        // No Effective Expiration Deadline
        // The function sets the deadline to the maximum uint256 value, which means the transaction can be executed at any time,
        // possibly under unfavorable market conditions.
        IUniswapV2Router02(UNISWAP_ROUTER).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            type(uint256).max // Setting deadline to max value
        );

        console.log("USDT", IERC20(USDT).balanceOf(address(this)));
    }

    receive() external payable {}
}

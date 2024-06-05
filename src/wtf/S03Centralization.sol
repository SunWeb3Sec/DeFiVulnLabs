// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/**
    WTF Solidity 合约安全: S03. 中心化风险

    ref https://www.wtf.academy/solidity-104/Centralization/

    command `forge test -vvv --contracts ./src/wtf/S03Centralization.sol`
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Centralization is ERC20, Ownable {
    constructor() ERC20("Centralization", "Cent") {
        address exposedAccount = msg.sender;
        transferOwnership(exposedAccount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract ContractTest is Test {
    function testCentralization() public {
        address alice = vm.addr(1);
        vm.startPrank(alice);
        Centralization centralization = new Centralization();

        // After alice deploying contract, her privatekey exposed to public.
        // So any one can mint any amount NFT to any address.
        centralization.mint(alice, 1);
    }
}

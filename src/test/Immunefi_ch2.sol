// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

//#SpotTheBugChallenge 
//https://twitter.com/immunefi/status/1562858386244665348?s=21&t=d7_HtNra5AGuNmzVtv9uKg
interface imp{
    function initialize(address) external;
}


contract ContractTest is Test {
        Proxy ProxyContract;
        Implementation ImplementationContract;

function testChallenge() public {
 
    ImplementationContract = new Implementation();
    console.log("ImplementationContract addr",address(ImplementationContract));
    ProxyContract = new Proxy(address(ImplementationContract));
    
    emit log_named_bytes32("Storage slot 0:",vm.load(address(ProxyContract),bytes32(uint256(0))));

    }
}
contract Proxy {
  //bytes32 constant internal _IMPLEMENTATION_SLOT = keccak256("where.bug.ser");  //correct pattern.
  bytes32 internal _IMPLEMENTATION_SLOT = keccak256("where.bug.ser");  // wrong

 constructor(address implementation){
    _setImplementation(address(0));
     Address.functionDelegateCall(implementation, abi.encodeWithSignature("initialize(address)", msg.sender));

 }
 fallback() external payable{
    address implementation = _getImplementation();
    Address.functionDelegateCall(implementation, msg.data);
 }

    function _setImplementation(address newImplementation) private {
        //require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }
    function _getImplementation() public view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

}

contract Implementation is Ownable, Initializable{
   // function initialize(address owner) external {    //test purpose
    function initialize(address owner) external initializer{
        _transferOwnership(owner);
    }
}


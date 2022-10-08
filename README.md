# DeFiVulnLabs
This was an internal Web3 solidity security training in [XREX](https://xrex.io/). I want to share these materials with everyone interested in Web3 security and how to find vulnerabilities in code and exploit them. Every vulnerability testing uses Foundry. Faster and easier!

A collection of vulnerable code snippets taken from [Solidity by Example](https://solidity-by-example.org/), [SWC Registry](https://swcregistry.io/) and [Blockchain CTF](https://github.com/blockthreat/blocksec-ctfs), etc.  
##### Education only! Please do not use it in production.

## Getting Started

* Follow the [instructions](https://book.getfoundry.sh/getting-started/installation.html) to install [Foundry](https://github.com/foundry-rs/foundry).
* Clone and install dependencies:```git submodule update --init --recursive```
* Test vulnerability: ```forge test --contracts ./src/test/Reentrancy.sol -vvvv``` 

## List of vulnerabilities
* [Integer Overflow 1](src/test/Overflow.sol) | [Integer Overflow 2](src/test/Overflow2.sol) : 
  * In previous versions of Solidity (prior Solidity 0.8.x) an integer would automatically roll-over to a lower or higher number.
  * Without SafeMath (prior Solidity 0.8.x)
* [Selfdestruct 1](src/test/Selfdestruct.sol) | [Selfdestruct 2](src/test/Selfdestruct2.sol) : 
  * Due to missing or insufficient access controls, malicious parties can self-destruct the contract.
  * The selfdestruct(address) function removes all bytecode from the contract address and sends all ether stored to the specified address.
* [Unsafe Delegatecall](src/test/Delegatecall.sol) : 
  * This allows a smart contract to dynamically load code from a different address at runtime.
* [Reentrancy](src/test/Reentrancy.sol) : 
  * One of the major dangers of calling external contracts is that they can take over the control flow. 
  * Not following [checks-effects-interactions](https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html) pattern and no ReentrancyGuard. 
* [ERC777 callbacks and reentrancy](src/test/ERC777-reentrancy.sol) : 
  * ERC777 tokens allow arbitrary callbacks via hooks that are called during token transfers. Malicious contract addresses may cause reentrancy on such callbacks if reentrancy guards are not used. [REF1](https://medium.com/cream-finance/c-r-e-a-m-finance-post-mortem-amp-exploit-6ceb20a630c5), [REF2](https://quantstamp.com/blog/how-the-dforce-hacker-used-reentrancy-to-steal-25-million), [Cream POC](https://github.com/SunWeb3Sec/DeFiHackLabs#20210830-cream-finance---flashloan-attack--reentrancy)
  * [ERC667 reentrancy](https://github.com/SunWeb3Sec/DeFiHackLabs#20220313-hundred-finance---erc667-reentrancy) | [ERC827 reentrancy](https://ethereum-magicians.org/t/erc-827-callbacks-can-lead-to-reentrancy-attack-vectors/660)
* [Unsafe low level call - call injection](src/test/UnsafeCall.sol) : 
  * Use of low level "call" should be avoided whenever possible. If the call value is controllable, it is easy to cause arbitrary function execution.
* [Private data](src/test/Privatedata.sol) : 
  * Private data ≠ Secure. It's readable from slots of the contract.
  * Because the storage of each smart contract is public and transparent, and the content can be read through the corresponding slot in the specified contract address. Sensitive information is not recommended to be placed in smart contract programs.
* [Unprotected callback - NFT over mint](src/test/Unprotected-callback.sol) : 
  * _safeMint is secure? Attacker can reenter the mint function inside the onERC721Received callback.
* [Backdoor assembly](src/test/Backdoor-assembly.sol) : 
  * An attacker can manipulate smart contracts as a backdoor by writing inline assembly. Any sensitive parameters can be changed at any time.
* [Bypass iscontract](src/test/Bypasscontract.sol) : 
  * The attacker only needs to write the code in the constructor of the smart contract to bypass the detection mechanism of whether it is a smart contract.
* [DOS](src/test/DOS.sol) : 
  * External calls can fail accidentally or deliberately, which can cause a DoS condition in the contract. For example, contracts that receive Ether do not contain fallback or receive functions. (DoS with unexpected revert)
* [Randomness](src/test/Randomness.sol) : 
  * Use of global variables like block hash, block number, block timestamp and other fields is insecure, miner and attacker can control it.
* [Visibility](src/test/Visibility.sol) : 
  * The default visibility of the function is Public. If there is an unsafe visibility setting, the attacker can directly call the sensitive function in the smart contract.
  * Real case : [FlippazOne NFT](https://github.com/SunWeb3Sec/DeFiHackLabs#20220706-flippazone-nft----accesscontrol) | [88mph NFT](https://github.com/SunWeb3Sec/DeFiHackLabs#20210607-88mph-nft---access-control) | [CoinstoreNFT Public Burn](https://etherscan.io/token/0x59585bbC68CDE26261Eb4B417A84aCAa5c5841db#code) | [Sandbox LAND Public Burn](https://etherscan.io/address/0x50f5474724e0Ee42D9a4e711ccFB275809Fd6d4a#code)
* [txorigin - phishing](src/test/txorigin.sol) : 
  * tx.origin is a global variable in Solidity;  using this variable for authentication in a smart contract makes the contract vulnerable to phishing attacks.
* [Uninitialized state variables](src/test/Uninitialized_variables.sol) : 
  * Uninitialized local storage variables may contain the value of other storage variables in the contract; this fact can cause unintentional vulnerabilities, or be exploited deliberately.
* [Storage collision 1](src/test/Storage-collision.sol) | [Storage collision 2 (Audius)](src/test/Storage-collision-audio.sol) : 
  * If variable’s storage location is fixed and it happens that there is another variable that has the same index/offset of the storage location in the implementation contract, then there will be a storage collision. [REF](https://blog.openzeppelin.com/proxy-patterns/)
* [Approval scam](src/test/ApproveScam.sol) : 
  * Most current scams use approve or setApprovalForAll to defraud your transfer rights. Be especially careful with this part.
* [Signature replay 1](src/test/SignatureReplay.sol) | [Signature replay 2 (NBA)](src/test/SignatureReplayNBA.sol): 
  * Missing protection against signature replay attacks, Same signature can be used multiple times to execute a function. [REF1](https://medium.com/cryptronics/signature-replay-vulnerabilities-in-smart-contracts-3b6f7596df57), [REF2](https://coinsbench.com/signature-replay-hack-solidity-13-735997ad02e5), [REF3](https://medium.com/cypher-core/replay-attack-vulnerability-in-ethereum-smart-contracts-introduced-by-transferproxy-124bf3694e25), [REF4](https://media.defcon.org/DEF%20CON%2026/DEF%20CON%2026%20presentations/DEFCON-26-Bai-Zheng-Chai-Wang-You-May-Have-Paid-more-than-You-Imagine.pdf), [REF5](https://github.com/OpenZeppelin/openzeppelin-contracts/security/advisories/GHSA-4h98-2769-gh6h)
* [Data location - storage vs memory](src/test/DataLocation.sol) : 
  * Incorrect use of storage slot and memory to save variable state can easily cause contracts to use values not updated for calculations. [REF1](https://mudit.blog/cover-protocol-hack-analysis-tokens-minted-exploit/), [REF2](https://www.educative.io/answers/storage-vs-memory-in-solidity)
* [DirtyBytes](src/test/Dirtybytes.sol) : 
  * Copying ``bytes`` arrays from memory or calldata to storage may result in dirty storage values.
* [Invariants](src/test/Invariant.sol) : 
  * Assert is used to check invariants. Those are states our contract or variables should never reach, ever. For example, if we decrease a value then it should never get bigger, only smaller. 
  
## Bug Reproduce
### 20220714 Sherlock Yield Strategy Bug - Cross-protocol Reentrancy
#### Bounty: $250K [POC](https://github.com/sherlock-protocol/bug-poc/) | [Reference](https://mirror.xyz/0xE400820f3D60d77a3EC8018d44366ed0d334f93C/LOZF1YBcH1eBdxlC6HP223cAMeTpNgQ-Kc4EjQuxmGA)


### 20220623 Sense Finance - Access control

Missing access control in onSwap()
#### Bounty: $50,000
Testing
```sh
forge test --contracts ./src/test/SenseFinance_exp.sol -vv 
```
#### Link reference
https://medium.com/immunefi/sense-finance-access-control-issue-bugfix-review-32e0c806b1a0

## Spotthebugchallenge
* [Immunefi #spotthebugchallenge 1](src/test/Immunefi_ch1.sol) : 
  * Incorrect check msg.value, we can mint many NFTs with 1 ETH.
* [Immunefi #spotthebugchallenge 2](src/test/Immunefi_ch2.sol) 

## Link reference

* [Mastering Ethereum - Smart Contract Security](https://github.com/ethereumbook/ethereumbook/blob/develop/09smart-contracts-security.asciidoc)
 
* [Ethereum Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/attacks/)

* [Awesome-Smart-Contract-Security](https://github.com/saeidshirazi/Awesome-Smart-Contract-Security)

* [(Not So) Smart Contracts](https://github.com/crytic/not-so-smart-contracts)

* [Smart Contract Attack Vectors](https://github.com/kadenzipfel/smart-contract-attack-vectors)

* [Secureum Security Pitfalls 101](https://secureum.substack.com/p/security-pitfalls-and-best-practices-101?s=r)

* [Secureum Security Pitfalls 201](https://secureum.substack.com/p/security-pitfalls-and-best-practices-201?s=r)
* [How to Secure Your Smart Contracts: 6 Solidity Vulnerabilities and how to avoid them (Part 1)](https://medium.com/loom-network/how-to-secure-your-smart-contracts-6-solidity-vulnerabilities-and-how-to-avoid-them-part-1-c33048d4d17d)[(Part 2)](https://medium.com/loom-network/how-to-secure-your-smart-contracts-6-solidity-vulnerabilities-and-how-to-avoid-them-part-2-730db0aa4834)
* [Top 10 DeFi Security Best Practices](https://blog.chain.link/defi-security-best-practices/)


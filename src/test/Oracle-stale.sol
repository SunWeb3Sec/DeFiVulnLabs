// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

/*
Demo: Oracle data feed is insufficiently validated

Chainlink price feed latestRoundData is used to retrieve price feed from chainlink. 
We need to makes sure that the answer is not negative and  price is not stale.

Mitigation
latestAnswer function is deprecated. Instead, use the latestRoundData function 
to retrieve the price and make sure to add checks for stale data.

REF
https://github.com/sherlock-audit/2023-02-blueberry-judging/issues/94
https://code4rena.com/reports/2022-10-inverse#m-17-chainlink-oracle-data-feed-is-not-sufficiently-validated-and-can-return-stale-price
https://docs.chain.link/data-feeds/historical-data#getrounddata-return-values
*/

contract ContractTest is Test {
    AggregatorV3Interface internal priceFeed;

    function setUp() public { 
        vm.createSelectFork("mainnet", 17568400);

        priceFeed= AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH/USD
    }

    function testUnSafePrice() public {
        //Chainlink oracle data feed is not sufficiently validated and can return stale price.
        (uint80 roundID, int256 answer, , , ) = priceFeed.latestRoundData();
        emit log_named_decimal_int("price",answer,8);
    }
 
    function testSafePrice() public {

        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        /*
        Mitigation:
        answeredInRound: The round ID in which the answer was computed
        updatedAt: Timestamp of when the round was updated
        answer: The answer for this round
        */
        require(answeredInRound >= roundId, "answer is stale");
        require(updatedAt > 0, "round is incomplete");
        require(answer > 0, "Invalid feed answer");
        emit log_named_decimal_int("price",answer,8);
    }

    receive() external payable {}
}

interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

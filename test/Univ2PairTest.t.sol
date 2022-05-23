// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Token.sol";
import "../src/Univ2Pair.sol";


contract Univ2PairTest is Test {

    Token token0;
    Token token1;
    Univ2Pair pair;
    function setUp() public {
        token0 = new Token("token 0","TK0");
        token1 = new Token("Token 1","TK1");
        pair = new Univ2Pair(address(token0),address(token1));

        token0.mint(10 ether);
        token1.mint(10 ether);
    }

    function testMintingWithNoInitialLiquidity() public {
        token0.transfer(address(pair),1 ether);
        token1.transfer(address(pair),1 ether);
        pair.mint();

        assertEq(pair.balanceOf(address(this)),1 ether - 1000);
        assertEq(token0.balanceOf(address(pair)),1 ether);
        assertEq(token1.balanceOf(address(pair)),1 ether);
    }

    function testBurn() public {

        token0.transfer(address(pair),1 ether);
        token1.transfer(address(pair),1 ether);

        pair.mint();

        pair.burn();

        assertEq(pair.balanceOf(address(this)),0);
        assertEq(token0.balanceOf(address(this)),10 ether - 1000);
        assertEq(token1.balanceOf(address(this)),10 ether - 1000);

    }
}

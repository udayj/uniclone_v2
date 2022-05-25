// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Token.sol";
import "../src/Univ2Pair.sol";
import "../src/Univ2Factory.sol";
import "../src/Univ2Router.sol";


contract Univ2PairTest is Test {

    Token token0;
    Token token1;
    address pair;
    Univ2Factory factory;
    Univ2Router router;
    function setUp() public {
        token0 = new Token("token 0","TK0");
        token1 = new Token("Token 1","TK1");

        factory = new Univ2Factory();
        //pair = factory.createPair(address(token0),address(token1));
        router = new Univ2Router(address(factory));
        token0.mint(10 ether);
        token1.mint(10 ether);
    }

    function testMintingWithNoInitialLiquidity() public {
        token0.approve(address(pair),1 ether);
        token1.approve(address(pair),1 ether);
        
        router.addLiquidity(
            address(token0),
            address(token1),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );
       // assertEq(pair.balanceOf(address(this)),1 ether - 1000);
        assertEq(token0.balanceOf(address(pair)),1 ether);
        assertEq(token1.balanceOf(address(pair)),1 ether);
    }

    function testBurn() public {

        token0.transfer(address(pair),1 ether);
        token1.transfer(address(pair),1 ether);

        router.addLiquidity(
            address(token0),
            address(token1),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

      //  pair.burn();

      //  assertEq(pair.balanceOf(address(this)),0);
        assertEq(token0.balanceOf(address(this)),10 ether - 1000);
        assertEq(token1.balanceOf(address(this)),10 ether - 1000);

    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IUniv2Factory.sol";
import "./interfaces/IUniv2Pair.sol";
import "./Univ2Library.sol";

contract Univ2Router {

    error SafeTransferFailed();
    IUniv2Factory factory;
    constructor(address _factory) {

        factory = IUniv2Factory(_factory);
    }

    function addLiquidity(

        address tokenA,
        address tokenB,
        uint256 amountAdesired,
        uint256 amountBdesired,
        uint256 amountAmin,
        uint256 amountBmin,
        address to
    ) public returns(uint256 amountA, uint256 amountB, uint256 liquidity) {

        address pair;
        if(factory.pairs(tokenA,tokenB) == address(0)) {
            pair=factory.createPair(tokenA, tokenB);
        }
        else {

            pair=Univ2Library.pairFor(address(factory), tokenA, tokenB);
        }

        (amountA, amountB) = _calculateLiquidity(
                                tokenA,
                                tokenB,
                                amountAdesired,
                                amountBdesired,
                                amountAmin,
                                amountBmin

        );

        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);

        liquidity = IUniv2Pair(pair).mint(to);
        return (amountA, amountB, liquidity);

    }

    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountAdesired,
        uint256 amountBdesired,
        uint256 amountAmin,
        uint256 amountBmin
    ) internal returns (uint256 amountA, uint256 amountB) {

        (uint256 reserveA, uint256 reserveB) = Univ2Library.getReserves(
            address(factory),
            tokenA,
            tokenB);

        if(reserveA==0 && reserveB==0){

            (amountA, amountB) = (amountAdesired, amountBdesired);
        }
        else {

            uint256 amountBOptimal = Univ2Library.quote(
                amountAdesired,
                reserveA,
                reserveB
            );

            if(amountBOptimal <= amountBdesired) {
                if(amountBOptimal >= amountBmin) {

                    (amountA, amountB) = (amountAdesired, amountBOptimal);
                }

            }
            else {

                uint256 amountAOptimal = Univ2Library.quote(
                amountBdesired,
                reserveB,
                reserveA
            );

                assert(amountAOptimal <= amountAdesired);

                if(amountAOptimal >= amountAmin) {
                    (amountA, amountB) = (amountAOptimal, amountBdesired);
                }   
            }

        }

        
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {

        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                value)
        );

        if(!success || (data.length!=0 && !abi.decode(data,(bool))))
            revert SafeTransferFailed();
    }
}
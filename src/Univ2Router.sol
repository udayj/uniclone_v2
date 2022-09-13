// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IUniv2Factory.sol";
import "./interfaces/IUniv2Pair.sol";
import "./Univ2Library.sol";

contract Univ2Router {

    error SafeTransferFailed();
    error InsufficientAmount();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error ExcessiveInputAmount();

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
    ) internal view returns (uint256 amountA, uint256 amountB) {

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

    function removeLiquidity(

        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAmin,
        uint256 amountBmin,
        address to
    ) public returns (uint256 amountA, uint256 amountB) {

        address pair = Univ2Library.pairFor(address(factory), tokenA, tokenB);

        IUniv2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        (amountA, amountB)=IUniv2Pair(pair).burn(to);

        if(amountA < amountAmin || amountB<amountBmin) revert InsufficientAmount();
        
    }

    

    function swapExactTokensForTokens(

        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public returns(uint256[] memory amounts) {

        amounts = Univ2Library.getAmountsOut(
            address(factory),
            amountIn,
            path
        );

        if(amounts[amounts.length-1] < amountOutMin)
            revert InsufficientOutputAmount();
        
        _safeTransferFrom(
            path[0],
            msg.sender,
            Univ2Library.pairFor(address(factory),path[0],path[1]),
            amounts[0]
        );

        _swap(amounts,path, to);
    }

    function swapTokensForExactTokens(

        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) public returns(uint256[] memory amounts) {

        amounts=Univ2Library.getAmountsIn(address(factory), amountOut, path);

        if(amounts[0] > amountInMax)
            revert ExcessiveInputAmount();

        _safeTransferFrom(
            path[0],
            msg.sender,
            Univ2Library.pairFor(
                address(factory),
                path[0],
                path[1]
            ),
            amounts[0]
        );

        _swap(amounts,path,to);
    }

    function _swap(uint256[] memory amounts, address[] memory path, address to_) internal {


        for(uint256 i;i<path.length-1;i++) {
            (address input, address output) = (path[i],path[i+1]);
            (address token0,) = Univ2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i+1];

            (uint256 amount0Out, uint256 amount1Out) = input ==token0 ? (uint256(0),amountOut) : (amountOut,uint256(0));


            address to = i<path.length-2 ? Univ2Library.pairFor(address(factory),output, path[i+2]): to_;

            IUniv2Pair(Univ2Library.pairFor(address(factory),input,output)).swap(amount0Out, amount1Out, to);

        }
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IUniv2Pair.sol";

library Univ2Library {

    error InsufficientAmount();
    error InsufficientLiquidity();
    error InvalidPath();

    function getReserves(
        address factoryAddress,
        address tokenA,
        address tokenB
    ) public view returns (uint256 reserveA, uint256 reserveB) {

        (address token0, ) = sortTokens(tokenA, tokenB);

        (uint256 reserve0, uint256 reserve1) = IUniv2Pair(pairFor(factoryAddress, tokenA, tokenB)).getReserves();

        (reserveA, reserveB) = tokenA==token0 ? (reserve0, reserve1): (reserve1, reserve0);
    }

    function pairFor(address factoryAddress, address tokenA, address tokenB) internal pure returns(address pairAddress) {

        (address token0, address token1) = sortTokens(tokenA, tokenB);

        pairAddress = address (uint160 (
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factoryAddress,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"d72ebdb61b2596ebc2f7e6d5ecf0afeb0b47ef526961241f25c10a7e92c2d2bc"
                    )
                )
            )
        ));
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns(address token0, address token1) {

        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

    }

    function quote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns(uint256 amountOut) {

        if (amountIn == 0) revert InsufficientAmount();
        if(reserveIn ==0 || reserveOut==0) revert InsufficientLiquidity();

        amountOut = (amountIn*reserveOut) / reserveIn;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns(uint256) {


        if(amountIn==0) revert InsufficientAmount();

        if(reserveIn==0 || reserveOut==0) revert InsufficientLiquidity();

        uint256 amountWithFee = amountIn*997;

        uint256 numerator = amountWithFee * reserveOut;
        uint256 denominator = (reserveIn*1000 + amountWithFee);

        return numerator / denominator;
    }

    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) public view returns (uint256[] memory) {
        if (path.length < 2) revert InvalidPath();
        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserve0, uint256 reserve1) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserve0, reserve1);
        }

        return amounts;
    }
}
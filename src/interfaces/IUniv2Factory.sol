// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IUniv2Factory {

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function pairs(address tokenA, address tokenB) external returns (address pair);
}
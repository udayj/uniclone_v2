// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IUniv2Pair {

    function initialize(address token0_, address token1_) external;
    function mint(address to) external returns(uint256);
    function getReserves() external view returns(uint112, uint112);
}
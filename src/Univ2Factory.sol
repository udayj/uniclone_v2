// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IUniv2Pair.sol";
import "./Univ2Pair.sol";


contract Univ2Factory {

    error IdenticalAddress();
    error ZeroAddress();
    error PairAlreadyExists();

    mapping ( address => mapping (address => address)) public pairs;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB) public returns (address pair) {

        if (tokenA ==tokenB) {
            revert IdenticalAddress();
        }

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB): (tokenB,tokenA);
        if (tokenA == address(0)) {
            revert ZeroAddress();
        }

        if(pairs[token0][token1]!=address(0)) {

            revert PairAlreadyExists();
        }

        bytes memory bytecode = type(Univ2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0,token1));

        assembly {

            pair := create2(0, add(bytecode,32), mload(bytecode), salt)
        }

        IUniv2Pair(pair).initialize(token0, token1);

        pairs[token0][token1]=pair;
        pairs[token1][token0]=pair;
        allPairs.push(pair);



    }
}
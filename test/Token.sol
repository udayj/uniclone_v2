// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20  {

    constructor(string memory name,string memory symbol) ERC20(name,symbol) {

    }

    function mint(uint256 amount) public {

        _mint(msg.sender,amount);
    }

}
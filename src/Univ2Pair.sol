// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Univ2Pair is ERC20 {

    uint256 private reserve0;
    uint256 private reserve1;
    address private token0;
    address private token1;
    uint256 public MINIMUM_LIQUIDITY=1000;
    event Mint(address liquidityProvider, uint256 amountToken0, uint256 amountToken1);

    constructor(address _token0, address _token1) ERC20 ("Uni token", "UNI"){

        require (_token0 != _token1, "Both tokens cannot be same");
        require (_token0!=address(0) && _token1!=address(0), "Neither token can be 0 address");

        token0=_token0;
        token1=_token1;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function mint() public {

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        uint256 liquidity=0;

        if(totalSupply() == 0){

            liquidity= sqrt(amount0*amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0),MINIMUM_LIQUIDITY);
        }
        else {
            liquidity= (totalSupply() * amount0) / reserve0;
            uint alt = (totalSupply() * amount1) / reserve1;
            if (liquidity > alt) {
                liquidity=alt;
            }
        }
        _mint(msg.sender,liquidity);

        _update(balance0, balance1);
         emit Mint(msg.sender, amount0, amount1);
    }

    function _update(uint256 _balance0, uint256 _balance1) private {

        reserve0=_balance0;
        reserve1=_balance1;
    }
}

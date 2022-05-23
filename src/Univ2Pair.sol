// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./lib/UQ112.sol";


error IncorrectOutputAmount();
error InsufficientLiquidity();
error InvalidK();
error TransferFailed();

contract Univ2Pair is ERC20 {

    using UQ112 for uint112;
    address private token0;
    address private token1;

    uint112 private reserve0;
    uint112 private reserve1;

    uint32 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint256 public MINIMUM_LIQUIDITY=1000;
    event Mint(address liquidityProvider, uint256 amountToken0, uint256 amountToken1);
    event Burn(address liquitidyProvider, uint256 amoutnToken0, uint256 amounttoken1);

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
            _mint(address(1),MINIMUM_LIQUIDITY); //OZ doesnt allow minting to 0 address
        }
        else {
            liquidity= (totalSupply() * amount0) / reserve0;
            uint alt = (totalSupply() * amount1) / reserve1;
            if (liquidity > alt) {
                liquidity=alt;
            }
        }
        _mint(msg.sender,liquidity);

        _update(balance0, balance1,uint112(amount0),uint112(amount1));
         emit Mint(msg.sender, amount0, amount1);
    }

    function _update(uint256 _balance0, uint256 _balance1, uint112 reserve0_, uint112 reserve1_) private {

        unchecked {

            uint32 timeElapsed = uint32(block.timestamp - blockTimestampLast);

            if (timeElapsed>0 && reserve0_>0 && reserve1 >0) {

                uint224 num1=UQ112.encode(reserve1_);
                price0CumulativeLast += 
                uint256(UQ112.uqdiv(num1, reserve0_))*timeElapsed;

                uint224 num0 = UQ112.encode(reserve0_);
                price1CumulativeLast +=
                uint256(UQ112.uqdiv(num0,reserve1_))*timeElapsed;

            }

            reserve0=uint112(_balance0);
            reserve1=uint112(_balance1);

            blockTimestampLast = uint32(block.timestamp);


        }

        reserve0=uint112(_balance0);
        reserve1=uint112(_balance1);
    }

    function burn() public {

        uint256 balance0= IERC20(token0).balanceOf(address(this));
        uint256 balance1= IERC20(token1).balanceOf(address(this));

        uint256 liquidity = balanceOf(msg.sender);

        uint256 amount0 = (liquidity*balance0)/totalSupply();
        uint256 amount1 = (liquidity*balance1)/totalSupply();

        _safeTransfer(token0, msg.sender,amount0);
        _safeTransfer(token1, msg.sender,amount1);
        _burn(msg.sender,liquidity);

        balance0= IERC20(token0).balanceOf(address(this));
        balance1= IERC20(token1).balanceOf(address(this));
        (uint112 reserve0_, uint112 reserve1_)=getReserves();
        _update(balance0,balance1,reserve0_,reserve1_);

        emit Burn(msg.sender, amount0, amount1);

    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) public {

        if(amount0Out == 0 && amount1Out == 0) {

            revert IncorrectOutputAmount();
        }

        (uint112 reserve0_, uint112 reserve1_) = getReserves();

        if(amount0Out > reserve0_ || amount1Out > reserve1_) {

            revert InsufficientLiquidity();
        }

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        if (balance0 * balance1 < reserve0_ * reserve1_) {
            revert InvalidK();
        }

        _update(balance0, balance1,reserve0_, reserve1_);

        if (amount0Out>0) {
            _safeTransfer(token0, to, amount0Out);
        }
        if(amount1Out>0) {
            _safeTransfer(token1, to, amount1Out);
        }
        

    }

    function getReserves() public view returns(uint112, uint112) {

        return (reserve0, reserve1);
    }

    function _safeTransfer(address token, address to, uint256 amount) private {

        (bool success, bytes memory data) =token.call(abi.encodeWithSignature("transfer(address,uint256)", to,amount));

        if(!success || (data.length!=0 && !abi.decode(data,(bool)))) {
            revert TransferFailed();
        }
    }
}

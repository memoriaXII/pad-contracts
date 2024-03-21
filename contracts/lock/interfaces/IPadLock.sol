// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IPadLock {
    function lockTokens(
        address _currency,
        address _owner,
        uint256 amount,
        uint256 endTime,
        bool isLPToken
    ) external returns (bool);
}

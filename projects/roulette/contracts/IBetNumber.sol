// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBetNumber {

    function patterns(uint256 format) external view returns (bool);
}

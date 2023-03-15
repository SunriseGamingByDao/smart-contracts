// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

interface ISUSD {
    function transferToSC(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function transferToSCAssign(address sc) external;

    function transferToSCHasRole(address sc) external view returns (bool);

    function burnFromSC(address reciever, uint256 amount) external;

    function burnFromSCAssign(address burner) external;

    function burnFromSCHasRole(address burner) external view returns (bool);
}

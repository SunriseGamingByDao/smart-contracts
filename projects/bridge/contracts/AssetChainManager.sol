// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AssetChainManager is AccessControlEnumerableUpgradeable {

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event TreasuryUpdated(address treasury);
    event FundWithdrawn(address recipient, uint256 amount);

    IERC20 public token;

    address public treasury;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "AssetChainManager: caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "AssetChainManager: caller is not operator");
        _;
    }

    function initialize(IERC20 _token)
        external
        initializer
    {
        __AccessControlEnumerable_init();

        token = _token;

        address msgSender = _msgSender();

        treasury = msgSender;

        _setupRole(DEFAULT_ADMIN_ROLE, msgSender);
        _setupRole(OPERATOR_ROLE, msgSender);
    }

    function setTreasury(address _treasury)
        external
        onlyAdmin
    {
        require(_treasury != address(0), "AssetChainManager: address is invalid");

        treasury = _treasury;

        emit TreasuryUpdated(_treasury);
    }

    function withdrawFund(uint256 _amount)
        external
        onlyOperator
    {
        require(_amount > 0, "AssetChainManager: amount is invalid");

        token.transfer(treasury, _amount);

        emit FundWithdrawn(treasury, _amount);
    }

}
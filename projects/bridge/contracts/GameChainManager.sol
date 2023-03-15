// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IGameChain {

    function withdrawOnAssetChainWithSpecifiedRecipient(address _recipient, uint256 _amount) external;
}

contract GameChainManager is AccessControlEnumerableUpgradeable {

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event ETHReceived(address sender, uint256 amount);
    event MinETHBalanceUpdated(uint256 balance);
    event ETHRefilled(address recipient, uint256 amount);
    event IncomeUpdated(address game, uint256 tableId, uint256 roundId, int256 income);
    event IncomeClaimed(uint256 claimId, int256 income);
    event AssetManagerUpdated(address assetManager);

    IERC20 public token;

    IGameChain public gameChain;

    uint256 public minETHBalance;

    int256 public currentIncome;

    mapping(uint256 => int256) public incomes;

    mapping(uint256 => bool) public claimed;

    address public assetManager;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GameChainManager: caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "GameChainManager: caller is not operator");
        _;
    }

    function initialize(IERC20 _token, IGameChain _gameChain, address _assetManager)
        external
        initializer
    {
        __AccessControlEnumerable_init();

        token = _token;
        gameChain = _gameChain;
        assetManager = _assetManager;

        minETHBalance = 0.5 ether;

        address msgSender = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, msgSender);
        _setupRole(OPERATOR_ROLE, msgSender);
    }

    receive()
        external
        payable
    {
        emit ETHReceived(_msgSender(), msg.value);
    }

    function setMinETHBalance(uint256 _balance)
        external
        onlyAdmin
    {
        minETHBalance = _balance;

        emit MinETHBalanceUpdated(_balance);
    }

    function setAssetManager(address _assetManager)
        external
        onlyAdmin
    {
        require(_assetManager != address(0), "GameChainManager: address is invalid");

        assetManager = _assetManager;

        emit AssetManagerUpdated(_assetManager);
    }

    function updateIncome(uint256 _tableId, uint256 _roundId, int256 _income)
        external
        onlyOperator
    {
        address msgSender = _msgSender();

        currentIncome += _income;

        emit IncomeUpdated(msgSender, _tableId, _roundId, _income);
    }

    function refillETH(address _recipient)
        external
        onlyOperator
    {
        require(_recipient != address(0), "GameChainManager: address is invalid");

        if (_recipient.balance >= minETHBalance) {
            return;
        }

        uint amount = minETHBalance - _recipient.balance;

        payable(_recipient).transfer(amount);

        emit ETHRefilled(_recipient, amount);
    }

    function transferToken(address _recipient, uint256 _amount)
        external
        onlyOperator
    {
        require(_amount > 0, "GameChainManager: amount is invalid");

        uint256 balance = token.balanceOf(address(this));

        if (_amount <= balance) {
            token.transfer(_recipient, _amount);

        } else {
            token.mint(_recipient, _amount);
        }
    }

    function claimIncome(uint256 id)
        external
        onlyOperator
    {
        require(!claimed[id], "GameChainManager: already claimed");

        claimed[id] = true;
        incomes[id] = currentIncome;

        if (currentIncome > 0) {
            token.approve(address(gameChain), uint256(currentIncome));

            gameChain.withdrawOnAssetChainWithSpecifiedRecipient(assetManager, uint256(currentIncome));
        }

        emit IncomeClaimed(id, currentIncome);

        currentIncome = 0;
    }
}

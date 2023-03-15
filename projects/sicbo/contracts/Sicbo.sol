// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "./IERC20.sol";
import "./IBetNumber.sol";

contract Sicbo is AccessControlEnumerableUpgradeable {

    uint256 public constant BIG_BET = 1;
    uint256 public constant SMALL_BET = 2;
    uint256 public constant ANY_TRIPLE_BET = 3;
    uint256 public constant SPECIFIC_TRIPLE_BET = 4;
    uint256 public constant DOUBLE_BET = 5;
    uint256 public constant TOTAL_4_17_BET = 6;
    uint256 public constant TOTAL_5_16_BET = 7;
    uint256 public constant TOTAL_6_15_BET = 8;
    uint256 public constant TOTAL_7_14_BET = 9;
    uint256 public constant TOTAL_8_13_BET = 10;
    uint256 public constant TOTAL_9_12_BET = 11;
    uint256 public constant TOTAL_10_11_BET = 12;
    uint256 public constant COMBINATION_BET = 13;
    uint256 public constant SINGLE_BET = 14;
    uint256 public constant ODD_BET = 15;
    uint256 public constant EVEN_BET = 16;

    uint256 public constant DICE_NUMBER = 6;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event Received(address sender, uint256 amount);
    event Refunded(address receiver, uint256 amount);
    event EmergencyWithdraw(address receiver, uint256 tokenAmount, uint256 ethAmount);
    event BetRateUpdated(uint256 betType, uint256 rate);
    event NumMaxBetsUpdated(uint256 value);
    event MinBalanceUpdated(uint256 value);
    event RoundTimeUpdated(uint256 time);
    event TableCreated(uint256 tableId);
    event TableDisabled(uint256 tableId);
    event TableEnabled(uint256 tableId);

    event RoundStarted(uint256 tableId, uint256 roundId, bytes32 secretHash);
    event BetPlaced(uint256 tableId, uint256 roundId, bytes32 seedHash, address account, uint256[] types, uint256[] amounts);
    event RoundEnded(uint256 tableId, uint256 roundId, uint256 secretValue);
    event RewardDistributed(uint256 tableId, uint256 roundId, address account, uint256 amount, uint256 betIndex);
    event RoundOutput(uint256 tableId, uint256 roundId, uint256[] dices, uint256 totaPoint, uint256 triple, uint256 double);

    struct Round {
        bytes32 random;
        bytes32 secretHash;
        uint256 secretValue;
        uint256 numBets;
        bool closed;
        uint256 startAt;
    }

    struct Bet {
        uint256[] types;
        uint256[] amounts;
        bytes32[] seedHashes;
    }

    IERC20 public token;

    IBetNumber public betNumber;

    // table id => current round id
    mapping(uint256 => uint256) private _currentRound;

    // table id => round id => round information
    mapping(uint256 => mapping(uint256 => Round)) public rounds;

    // table id => round id => participants
    mapping(uint256 => mapping(uint256 => address[])) private _participants;

    // table id => round id => user address => bet information
    mapping(uint256 => mapping(uint256 => mapping(address => Bet))) private _bets;

    // bet type => rate
    mapping(uint256 => uint256) public betRates;

    uint256 public minBalance;

    uint256 public numMaxBets;

    uint256[] private _activeTables;

    uint256[] private _inactiveTables;

    mapping(uint256 => uint256) private _activeTableIndexs;
    mapping(uint256 => uint256) private _inactiveTableIndexs;

    uint256 private _tableCount;

    uint256 public roundTime;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sicbo: caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Sicbo: caller is not operator");
        _;
    }

    function initialize(IBetNumber _betNumber, IERC20 _token)
        public
        initializer
    {
        __AccessControlEnumerable_init();

        betNumber = _betNumber;
        token = _token;

        address msgSender = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, msgSender);
        _setupRole(OPERATOR_ROLE, msgSender);

        minBalance = 0.5 ether;
        numMaxBets = 5000;
        roundTime = 1 minutes;

        betRates[BIG_BET] = 1;
        betRates[SMALL_BET] = 1;
        betRates[ANY_TRIPLE_BET] = 24;
        betRates[SPECIFIC_TRIPLE_BET] = 150;
        betRates[DOUBLE_BET] = 8;
        betRates[TOTAL_4_17_BET] = 50;
        betRates[TOTAL_5_16_BET] = 18;
        betRates[TOTAL_6_15_BET] = 14;
        betRates[TOTAL_7_14_BET] = 12;
        betRates[TOTAL_8_13_BET] = 8;
        betRates[TOTAL_9_12_BET] = 6;
        betRates[TOTAL_10_11_BET] = 6;
        betRates[COMBINATION_BET] = 5;
        betRates[SINGLE_BET] = 1;
        betRates[ODD_BET] = 1;
        betRates[EVEN_BET] = 1;

        _activeTables.push(0);
        _inactiveTables.push(0);
    }

    receive()
        external
        payable
    {
        emit Received(_msgSender(), msg.value);
    }

    function setBetRate(uint256 betType, uint256 rate)
        public
        onlyAdmin
    {
        betRates[betType] = rate;

        emit BetRateUpdated(betType, rate);

        _refund(_msgSender());
    }

    function setNumMaxBets(uint256 value)
        public
        onlyOperator
    {
        numMaxBets = value;

        emit NumMaxBetsUpdated(value);

        _refund(_msgSender());
    }

    function setMinBalance(uint256 value)
        public
        onlyOperator
    {
        minBalance = value;

        emit MinBalanceUpdated(value);

        _refund(_msgSender());
    }

    function setRoundTime(uint256 time)
        public
        onlyOperator
    {
        roundTime = time;

        emit RoundTimeUpdated(time);

        _refund(_msgSender());
    }

    function getCurrentRound(uint256 tableId)
        public
        view
        returns (uint256)
    {
        return _currentRound[tableId] + 1;
    }

    function getTotalParticipants(uint256 tableId, uint256 roundId)
        public
        view
        returns (uint256)
    {
        return _participants[tableId][roundId].length;
    }

    function getParticipants(uint256 tableId, uint256 roundId)
        public
        view
        returns (address[] memory)
    {
        return _participants[tableId][roundId];
    }

    function getBets(uint256 tableId, uint256 roundId, address account)
        public
        view
        returns (uint256[] memory, uint256[] memory, bytes32[] memory)
    {
        Bet memory bet = _bets[tableId][roundId][account];

        return (bet.types, bet.amounts, bet.seedHashes);
    }

    function getHash(uint256 value)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(value));
    }

    function createTable()
        public
        onlyOperator
    {
        uint256 id = ++_tableCount;

        _activeTableIndexs[id] = _activeTables.length;

        _activeTables.push(id);

        emit TableCreated(id);
    }

    function enableTable(uint256 tableId)
        public
        onlyOperator
    {
        uint256 index = _inactiveTableIndexs[tableId];

        require(_activeTableIndexs[tableId] == 0 && index != 0, "Sicbo: table id is invalid");

        _inactiveTableIndexs[tableId] = 0;

        _inactiveTables[index] = _inactiveTables[_inactiveTables.length - 1];
        _inactiveTables.pop();

        _activeTableIndexs[tableId] = _activeTables.length;

        _activeTables.push(tableId);

        emit TableEnabled(tableId);
    }

    function disableTable(uint256 tableId)
        public
        onlyOperator
    {
        uint256 index = _activeTableIndexs[tableId];

        require(_inactiveTableIndexs[tableId] == 0 && index != 0, "Sicbo: table id is invalid");

        _activeTableIndexs[tableId] = 0;

        _activeTables[index] = _activeTables[_activeTables.length - 1];
        _activeTables.pop();

        _inactiveTableIndexs[tableId] = _inactiveTables.length;

        _inactiveTables.push(tableId);

        emit TableDisabled(tableId);
    }

    function getActiveTables()
        public
        view
        returns (uint256[] memory)
    {
        return _activeTables;
    }

    function getInactiveTables()
        public
        view
        returns (uint256[] memory)
    {
        return _inactiveTables;
    }

    function startRound(uint256 tableId, uint256 currentSecretValue, bytes32 nextSecretHash)
        public
        onlyOperator
    {
        uint256 roundId;

        if (currentSecretValue != 0) {
            roundId = getCurrentRound(tableId);

            Round storage round = rounds[tableId][roundId];

            require(block.timestamp >= round.startAt + roundTime, "Sicbo: round is running");

            bytes32 secretHash = round.secretHash;

            require(secretHash != 0 && secretHash == getHash(currentSecretValue), "Sicbo: secret value is invalid");

            round.random ^= getHash(uint256(secretHash) ^ currentSecretValue ^ block.timestamp);
            round.secretValue = currentSecretValue;
            round.closed = true;

            _distributeReward(tableId, roundId);

            _currentRound[tableId]++;

            emit RoundEnded(tableId, roundId, currentSecretValue);
        }

        if (_activeTableIndexs[tableId] == 0) {
            return;
        }

        require(nextSecretHash != 0, "Sicbo: secret hash is invalid");

        roundId = getCurrentRound(tableId);

        require(rounds[tableId][roundId].secretHash == 0, "Sicbo: round was started");

        rounds[tableId][roundId] = Round(0, nextSecretHash, 0, 0, false, block.timestamp);

        emit RoundStarted(tableId, roundId, nextSecretHash);

        _refund(_msgSender());
    }

    function placeBet(uint256 tableId, bytes32 seedHash, uint256[] memory types, uint256[] memory amounts)
        public
    {
        require(seedHash != 0, "Sicbo: seed hash is invalid");

        uint256 length = types.length;

        require(length > 0 && length == amounts.length, "Sicbo: length of arrays is invalid");

        uint256 roundId = getCurrentRound(tableId);

        Round storage round = rounds[tableId][roundId];

        require(round.secretHash != 0, "Sicbo: round is not started yet");

        require(round.numBets + length <= numMaxBets, "Sicbo: number of bets reach maximum");

        round.random ^= seedHash;

        round.numBets += length;

        address msgSender = _msgSender();

        Bet storage bet = _bets[tableId][roundId][msgSender];

        if (bet.types.length == 0) {
            _participants[tableId][roundId].push(msgSender);
        }

        bet.seedHashes.push(seedHash);

        uint256 total;

        for (uint256 i = 0; i < length; i++) {
            require(amounts[i] > 0, "Sicbo: amount is invalid");

            require(betNumber.patterns(types[i]), "Sicbo: bet type is invalid");

            bet.types.push(types[i]);
            bet.amounts.push(amounts[i]);

            total += amounts[i];
        }

        token.transferFrom(msgSender, address(this), total);

        emit BetPlaced(tableId, roundId, seedHash, msgSender, types, amounts);

        _refund(msgSender);
    }

    function _refund(address account)
        private
    {
        if (account.balance >= minBalance) {
            return;
        }

        uint amount = minBalance - account.balance;

        payable(account).transfer(amount);

        emit Refunded(account, amount);
    }

    function _distributeReward(uint256 tableId, uint256 roundId)
        private
    {
        (uint256[] memory dices, uint256 totaPoint, uint256 triple, uint256 double) = getResult(tableId, roundId);
        emit RoundOutput(tableId, roundId, dices, totaPoint, triple, double);

        uint256 balance = token.balanceOf(address(this));

        address[] memory players = _participants[tableId][roundId];

        for (uint256 i = 0; i < players.length; i++) {
            Bet memory bet = _bets[tableId][roundId][players[i]];

            for (uint256 j = 0; j < bet.types.length; j++) {
                uint256 amount = bet.amounts[j];

                (bool result, uint256 betRate) = isWinner(dices, totaPoint, triple, double, bet.types[j]);

                if (!result) {
                    continue;
                }

                uint256 reward = amount * betRate + amount;

                if (reward <= balance) {
                    token.transfer(players[i], reward);

                    balance -= reward;

                } else {
                    token.mint(players[i], reward);
                }

                emit RewardDistributed(tableId, roundId, players[i], amount, j);
            }
        }
    }

    function getResult(uint256 tableId, uint256 roundId)
        public
        view
        returns (uint256[] memory dices, uint256 totaPoint, uint256 triple, uint256 double)
    {
        dices = new uint256[](3);

        Round memory round = rounds[tableId][roundId];

        if (!round.closed) {
            return (dices, totaPoint, triple, double);
        }

        uint256 random = uint256(round.random);

        uint256 cnt = 0;

        // Generates dices
        while (cnt < 3) {
            uint256 dice = random % DICE_NUMBER + 1;

            dices[cnt++] = dice;

            totaPoint += dice;

            random = uint256(keccak256(abi.encodePacked(random)));
        }

        if (dices[0] == dices[1] && dices[1] == dices[2]) {
            triple = dices[0];
            double = dices[0];

        } else if (dices[0] == dices[1] || dices[0] == dices[2]) {
            double = dices[0];

        } else if (dices[1] == dices[2]) {
            double = dices[1];
        }

        return (dices, totaPoint, triple, double);
    }

    function getWinners(uint256 tableId, uint256 roundId)
        public
        view
        returns (address[] memory accounts, uint256[] memory amounts, uint256[] memory indexes)
    {
        (uint256 cnt, address[] memory tmpAccounts, uint256[] memory tmpAmounts, uint256[] memory tmpIndexes) = _getWinners(tableId, roundId);

        accounts = new address[](cnt);
        amounts = new uint256[](cnt);
        indexes = new uint256[](cnt);

        for (uint256 i = 0; i < cnt; i++) {
            accounts[i] = tmpAccounts[i];
            amounts[i] = tmpAmounts[i];
            indexes[i] = tmpIndexes[i];
        }
    }

    function _getWinners(uint256 tableId, uint256 roundId)
        private
        view
        returns (uint256 cnt, address[] memory accounts, uint256[] memory amounts, uint256[] memory indexes)
    {
        uint256 size = rounds[tableId][roundId].numBets;

        accounts = new address[](size);
        amounts = new uint256[](size);
        indexes = new uint256[](size);

        (uint256[] memory dices, uint256 totaPoint, uint256 triple, uint256 double) = getResult(tableId, roundId);

        if (totaPoint != 0) {
            address[] memory players = _participants[tableId][roundId];

            for (uint256 i = 0; i < players.length; i++) {
                Bet memory bet = _bets[tableId][roundId][players[i]];

                for (uint256 j = 0; j < bet.types.length; j++) {
                    (bool result,) = isWinner(dices, totaPoint, triple, double, bet.types[j]);

                    if (!result) {
                        continue;
                    }

                    accounts[cnt] = players[i];
                    amounts[cnt] = bet.amounts[j];
                    indexes[cnt] = j;

                    cnt++;
                }
            }
        }
    }

    function isWinner(uint256[] memory dices, uint256 totaPoint, uint256 triple, uint256 double, uint256 pattern)
        public
        view
        returns (bool, uint256)
    {
        uint8 betType = uint8(bytes32(pattern)[0]);
        uint8 number1 = uint8(bytes32(pattern)[1]);

        uint256 betRate = betRates[betType];

        if (betType == BIG_BET) {
            if (totaPoint >= 11 && totaPoint <= 17 && triple == 0) {
                return (true, betRate);
            }

        } else if (betType == SMALL_BET) {
            if (totaPoint >= 4 && totaPoint <= 10 && triple == 0) {
                return (true, betRate);
            }

        } else if (betType == ANY_TRIPLE_BET) {
            if (triple > 0) {
                return (true, betRate);
            }

        } else if (betType == SPECIFIC_TRIPLE_BET) {
            if (triple == number1) {
                return (true, betRate);
            }

        } else if (betType == DOUBLE_BET) {
            if (double == number1) {
                return (true, betRate);
            }

        } else if (betType >= TOTAL_4_17_BET && betType <= TOTAL_10_11_BET) {
            if (totaPoint == number1) {
                return (true, betRate);
            }

        } else if (betType == COMBINATION_BET) {
            uint8 number2 = uint8(bytes32(pattern)[2]);

            if ((number1 == dices[0] || number1 == dices[1] || number1 == dices[2]) && (number2 == dices[0] || number2 == dices[1] || number2 == dices[2])) {
                return (true, betRate);
            }

        } else if (betType == SINGLE_BET) {
            if (number1 == dices[0] || number1 == dices[1] || number1 == dices[2]) {
                if (number1 == triple) {
                    betRate *= 3;

                } else if (number1 == double) {
                    betRate *= 2;
                }

                return (true, betRate);
            }

        } else if (betType == ODD_BET) {
            if (totaPoint % 2 != 0) {
                return (true, betRate);
            }

        } else if (betType == EVEN_BET) {
            if (totaPoint % 2 == 0) {
                return (true, betRate);
            }
        }

        return (false, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "./IERC20.sol";
import "./IBetNumber.sol";
import "./ErrorCode.sol";

contract Roulette is AccessControlEnumerableUpgradeable, GameRouletteError {

    uint256 public constant BET_WITHDRAWED = 1;
    uint256 public constant BET_IMPRISONED = 2;

    // Bet types
    uint256 public constant STRAIGHT_UP_BET = 1;
    uint256 public constant SPLIT_BET = 2;
    uint256 public constant STREET_BET = 3;
    uint256 public constant CORNER_BET = 4;
    uint256 public constant LINE_BET = 5;
    uint256 public constant COLUMN_BET = 6;
    uint256 public constant DOZEN_BET = 7;
    uint256 public constant COLOR_BET = 8;
    uint256 public constant ODD_EVEN_BET = 9;
    uint256 public constant LOW_HIGH_BET = 10;

    uint256 public constant ROULETTE_NUMBER = 37;

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
    event BetPlaced(uint256 tableId, uint256 roundId, bytes32 seedHash, address account, uint256[] numbers, uint256[] amounts);
    event RoundEnded(uint256 tableId, uint256 roundId, uint256 secretValue);
    event RoundOutput(uint256 tableId, uint256 roundId, uint256 rouletteNumber);
    event RewardDistributed(uint256 tableId, uint256 roundId, address account, uint256 number, uint256 amount, uint256 betIndex, bool isImprisoned);
    event BetWithdrawed(uint256 tableId, uint256 roundId, address account, uint256 number, uint256 amount, uint256 betIndex);
    event BetImprisoned(uint256 tableId, uint256 roundId, address account, uint256 number, uint256 amount, uint256 betIndex);

    event MaxTotalBetsAmountUpdated(uint256 tableId, uint256 value);
    event MaxBetsAmountUpdated(uint256 tableId, uint256[] numbers, uint256[] values );
    event MaxBetsAmountReset(uint256 tableId);

    event MinTotalBetsAmountUpdated(uint256 tableId, uint256 value);
    event MinBetsAmountUpdated(uint256 tableId, uint256[] numbers, uint256[] values );
    event MinBetsAmountReset(uint256 tableId);

    struct Round {
        bytes32 random;
        bytes32 secretHash;
        uint256 secretValue;
        uint256 numBets;
        bool closed;
        uint256 startAt;
        uint256 maxBetAmount;
        uint256 totalAmount;
        uint256 minBetAmount;
    }

    struct Bet {
        uint256[] numbers;
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

    // table id => round id => user address => bet index => status
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) private _enPrisonBets;

    // table id => round id => user address => bet index => status
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(uint256 => bool)))) private _imprisonedBets;

    // bet type => rate
    mapping(uint256 => uint256) public betRates;

    // table id => maxTotalBet
    mapping(uint256 => uint256) private _maxTotalBetsAmount;

    // table id => round id => betType => max bet of round
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public maxBetsAmount;

    uint256 public minBalance;

    uint256 public numMaxBets;

    uint256[] private _activeTables;

    uint256[] private _inactiveTables;

    mapping(uint256 => uint256) private _activeTableIndexs;
    mapping(uint256 => uint256) private _inactiveTableIndexs;

    uint256 private _tableCount;

    uint256 public roundTime;

     // table id => minTotalBet
    mapping(uint256 => uint256) private _minTotalBetsAmount;

    // table id => round id => betType => min bet of round
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public minBetsAmount;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), NOT_ROLE_ADMIN);
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), NOT_ROLE_OPERATOR);
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

        _maxTotalBetsAmount[0] = 1000000000;

        maxBetsAmount[0][0][STRAIGHT_UP_BET] = 25000000;
        maxBetsAmount[0][0][SPLIT_BET] = 50000000;
        maxBetsAmount[0][0][STREET_BET] = 75000000;
        maxBetsAmount[0][0][CORNER_BET] = 100000000;
        maxBetsAmount[0][0][LINE_BET] = 150000000;
        maxBetsAmount[0][0][COLUMN_BET] = 300000000;
        maxBetsAmount[0][0][COLOR_BET] = 1000000000;


        betRates[STRAIGHT_UP_BET] = 35;
        betRates[SPLIT_BET] = 17;
        betRates[STREET_BET] = 11;
        betRates[CORNER_BET] = 8;
        betRates[LINE_BET] = 5;
        betRates[COLUMN_BET] = 2;
        betRates[DOZEN_BET] = 2;
        betRates[COLOR_BET] = 1;
        betRates[ODD_EVEN_BET] = 1;
        betRates[LOW_HIGH_BET] = 1;

        _activeTables.push(0);
        _inactiveTables.push(0);

        _minTotalBetsAmount[0] = 0;

        minBetsAmount[0][0][STRAIGHT_UP_BET] = 0;
        minBetsAmount[0][0][SPLIT_BET] = 0;
        minBetsAmount[0][0][STREET_BET] = 0;
        minBetsAmount[0][0][CORNER_BET] = 0;
        minBetsAmount[0][0][LINE_BET] = 0;
        minBetsAmount[0][0][COLUMN_BET] = 0;
        minBetsAmount[0][0][COLOR_BET] = 0;
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

        return (bet.numbers, bet.amounts, bet.seedHashes);
    }

    function getBetStatus(uint256 tableId, uint256 roundId, address account, uint256 betIndex)
        public
        view
        returns (bool)
    {
        return _imprisonedBets[tableId][roundId][account][betIndex];
    }

    function setMaxTotalBetsAmount(uint256 tableId, uint256 value)
        public
        onlyOperator
    {
        require (tableId > 0 && tableId <= _tableCount, INVALID_TABLE_ID);

        _maxTotalBetsAmount[tableId] = value;

        emit MaxTotalBetsAmountUpdated(tableId, value);

        _refund(_msgSender());
    }

    function setDefaultMaxTotalBets(uint256 value)
        public
        onlyOperator
    {
        _maxTotalBetsAmount[0] = value;

        emit MaxTotalBetsAmountUpdated(0, value);

        _refund(_msgSender());
    }

    function setMaxBetsAmount(uint256 tableId, uint256[] memory numbers, uint256[] memory values)
        public
        onlyOperator
    {
        for(uint256 i = 0; i < numbers.length; i++) {
            maxBetsAmount[tableId][0][numbers[i]] = values[i];
        }

        emit MaxBetsAmountUpdated(tableId, numbers, values);

        _refund(_msgSender());
    }

    function resetDefaultMaxBetsAmount(uint256 tableId)
        public
        onlyOperator
    {
        for (uint256 i = 1; i <= 10; i++) {
            maxBetsAmount[tableId][0][i] = maxBetsAmount[0][0][i];
        }

        emit MaxBetsAmountReset(tableId);

        _refund(_msgSender());
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

        _maxTotalBetsAmount[id] = _maxTotalBetsAmount[0];
        _minTotalBetsAmount[id] = _minTotalBetsAmount[0];

        for (uint256 i = 1; i <= 10; i++) {
            maxBetsAmount[id][0][i] = maxBetsAmount[0][0][i];
            minBetsAmount[id][0][i] = minBetsAmount[0][0][i];
        }

        emit TableCreated(id);
    }

    function enableTable(uint256 tableId)
        public
        onlyOperator
    {
        uint256 index = _inactiveTableIndexs[tableId];

        require(_activeTableIndexs[tableId] == 0 && index != 0, INVALID_TABLE_ID);

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

        require(_inactiveTableIndexs[tableId] == 0 && index != 0, INVALID_TABLE_ID);

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

            require(block.timestamp >= round.startAt + roundTime, ROUND_IS_RUNNING);

            bytes32 secretHash = round.secretHash;

            require(secretHash != 0 && secretHash == getHash(currentSecretValue), INVALID_SECRET_VALUE);

            round.random ^= getHash(uint256(secretHash) ^ currentSecretValue ^ block.timestamp);
            round.secretValue = currentSecretValue;
            round.closed = true;

            (uint rouletteNumber, uint256 mask) = getWinningNumber(tableId, roundId);
            emit RoundOutput(tableId, roundId, rouletteNumber);

            _distributeReward(tableId, roundId, mask);

            _currentRound[tableId]++;

            emit RoundEnded(tableId, roundId, currentSecretValue);
        }

        if (_activeTableIndexs[tableId] == 0) {
            return;
        }

        require(nextSecretHash != 0, INVALID_SECRET_HASH);

        roundId = getCurrentRound(tableId);

        require(rounds[tableId][roundId].secretHash == 0, ROUND_WAS_STARTED);

        rounds[tableId][roundId] = Round(0, nextSecretHash, 0, rounds[tableId][roundId].numBets, false, block.timestamp, _maxTotalBetsAmount[tableId], 0, _minTotalBetsAmount[tableId]);

        for (uint256 i = 1; i <= 10; i++) {
            maxBetsAmount[tableId][roundId][i] = maxBetsAmount[tableId][0][i];
            minBetsAmount[tableId][roundId][i] = minBetsAmount[tableId][0][i];
        }

        emit RoundStarted(tableId, roundId, nextSecretHash);

        _refund(_msgSender());
    }

    function placeBet(uint256 tableId, bytes32 seedHash, uint256[] memory numbers, uint256[] memory amounts)
        public
    {
        require(seedHash != 0, INVALID_SEED_HASH);

        uint256 length = numbers.length;

        require(length > 0 && length == amounts.length, INVALID_LENGTH_ARRAY);

        uint256 roundId = getCurrentRound(tableId);

        Round storage round = rounds[tableId][roundId];

        require(round.secretHash != 0, ROUND_IS_NOT_START);

        require(round.numBets + length <= numMaxBets, REACH_MAX_BETS);

        round.random ^= seedHash;

        round.numBets += length;

        address msgSender = _msgSender();

        Bet storage bet = _bets[tableId][roundId][msgSender];

        if (bet.numbers.length == 0) {
            _participants[tableId][roundId].push(msgSender);
        }

        bet.seedHashes.push(seedHash);

        uint256 total;

        for (uint256 i = 0; i < length; i++) {

            uint256 maxBetAllowed = maxBetsAmount[tableId][roundId][numbers[i]];
            uint256 minBetAllowed = minBetsAmount[tableId][roundId][numbers[i]];

            require(amounts[i] > 0, INVALID_AMOUNT);

            require(betNumber.patterns(numbers[i]), INVALID_BET_NUMBER);

            require(round.totalAmount + amounts[i] <= round.maxBetAmount, EXCEED_TOTAL_AMOUNT);

            require( maxBetAllowed == 0 || amounts[i] <= maxBetAllowed , EXCEED_MAX_BET_AMOUNT);

            require(minBetAllowed == 0 || amounts[i] >= minBetAllowed , EXCEED_MIN_BET_AMOUNT);

            bet.numbers.push(numbers[i]);
            bet.amounts.push(amounts[i]);

            total += amounts[i];

            round.totalAmount += amounts[i];
        }

        require(total >= round.minBetAmount, EXCEED_TOTAL_MIN_BET);

        token.transferFrom(msgSender, address(this), total);

        emit BetPlaced(tableId, roundId, seedHash, msgSender, numbers, amounts);

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

    function _distributeReward(uint256 tableId, uint256 roundId, uint256 mask)
        private
    {
        uint256 balance = token.balanceOf(address(this));

        address[] memory players = _participants[tableId][roundId];

        uint256 numPlayers = players.length;

        for (uint256 i = 0; i < numPlayers; i++) {
            Bet memory bet = _bets[tableId][roundId][players[i]];

            uint256 numBets = bet.numbers.length;

            for (uint256 j = 0; j < numBets; j++) {
                uint256 number = bet.numbers[j];
                uint256 amount = bet.amounts[j];

                if (number & mask == 0) {
                    continue;
                }

                uint256 reward;

                bool isImprisoned = _imprisonedBets[tableId][roundId][players[i]][j];

                if (isImprisoned) {
                    reward = amount;

                } else {
                    uint8 betType = uint8(bytes32(number)[0]);

                    reward = amount * betRates[betType] + amount;
                }

                if (reward <= balance) {
                    token.transfer(players[i], reward);

                    balance -= reward;

                } else {
                    token.mint(players[i], reward);
                }

                emit RewardDistributed(tableId, roundId, players[i], number, amount, j, isImprisoned);
            }
        }
    }

    function getWinningNumber(uint256 tableId, uint256 roundId)
        public
        view
        returns (uint256, uint256)
    {
        Round memory round = rounds[tableId][roundId];

        if (!round.closed) {
            return (0, 0);
        }

        uint256 number = uint256(round.random) % ROULETTE_NUMBER;

        return (number, 1 << number);
    }

    function getWinners(uint256 tableId, uint256 roundId)
        public
        view
        returns (address[] memory accounts, uint256[] memory numbers, uint256[] memory amounts, uint256[] memory indexes, bool[] memory status)
    {
        (uint256 cnt, address[] memory tmpAccounts, uint256[] memory tmpNumbers, uint256[] memory tmpAmounts, uint256[] memory tmpIndexes) = _getWinners(tableId, roundId);

        accounts = new address[](cnt);
        numbers = new uint256[](cnt);
        amounts = new uint256[](cnt);
        indexes = new uint256[](cnt);
        status = new bool[](cnt);

        for (uint256 i = 0; i < cnt; i++) {
            accounts[i] = tmpAccounts[i];
            numbers[i] = tmpNumbers[i];
            amounts[i] = tmpAmounts[i];
            indexes[i] = tmpIndexes[i];
            status[i] = _imprisonedBets[tableId][roundId][accounts[i]][indexes[i]];
        }
    }

    function _getWinners(uint256 tableId, uint256 roundId)
        private
        view
        returns (uint256 cnt, address[] memory accounts, uint256[] memory numbers, uint256[] memory amounts, uint256[] memory indexes)
    {
        uint256 size = rounds[tableId][roundId].numBets;

        accounts = new address[](size);
        numbers = new uint256[](size);
        amounts = new uint256[](size);
        indexes = new uint256[](size);

        (, uint256 mask) = getWinningNumber(tableId, roundId);

        if (mask != 0) {
            address[] memory players = _participants[tableId][roundId];

            for (uint256 i = 0; i < players.length; i++) {
                Bet memory bet = _bets[tableId][roundId][players[i]];

                for (uint256 j = 0; j < bet.numbers.length; j++) {
                    if (bet.numbers[j] & mask == 0) {
                        continue;
                    }

                    accounts[cnt] = players[i];
                    numbers[cnt] = bet.numbers[j];
                    amounts[cnt] = bet.amounts[j];
                    indexes[cnt] = j;

                    cnt++;
                }
            }
        }
    }

    function getEnPrisonBets(uint256 tableId, uint256 roundId)
        public
        view
        returns (address[] memory accounts, uint256[] memory numbers, uint256[] memory amounts, uint256[] memory indexes, uint256[] memory status)
    {
        (uint256 cnt, address[] memory tmpAccounts, uint256[] memory tmpNumbers, uint256[] memory tmpAmounts, uint256[] memory tmpIndexes) = _getEnPrisonBets(tableId, roundId);

        accounts = new address[](cnt);
        numbers = new uint256[](cnt);
        amounts = new uint256[](cnt);
        indexes = new uint256[](cnt);
        status = new uint256[](cnt);

        for (uint256 i = 0; i < cnt; i++) {
            accounts[i] = tmpAccounts[i];
            numbers[i] = tmpNumbers[i];
            amounts[i] = tmpAmounts[i];
            indexes[i] = tmpIndexes[i];
            status[i] = _enPrisonBets[tableId][roundId][accounts[i]][indexes[i]];
        }
    }

    function _getEnPrisonBets(uint256 tableId, uint256 roundId)
        private
        view
        returns (uint256 cnt, address[] memory accounts, uint256[] memory numbers, uint256[] memory amounts, uint256[] memory indexes)
    {
        {
            uint256 size = rounds[tableId][roundId].numBets;

            accounts = new address[](size);
            numbers = new uint256[](size);
            amounts = new uint256[](size);
            indexes = new uint256[](size);
        }

        (uint256 winnerNumber, uint256 mask) = getWinningNumber(tableId, roundId);

        if (mask != 0 && winnerNumber == 0) {
            address[] memory players = _participants[tableId][roundId];

            for (uint256 i = 0; i < players.length; i++) {
                Bet memory bet = _bets[tableId][roundId][players[i]];

                for (uint256 j = 0; j < bet.numbers.length; j++) {
                    uint8 betType = uint8(bytes32(bet.numbers[j])[0]);

                    if (betType != COLOR_BET && betType != ODD_EVEN_BET && betType != LOW_HIGH_BET) {
                        continue;
                    }

                    if (_imprisonedBets[tableId][roundId][players[i]][j]) {
                        continue;
                    }

                    accounts[cnt] = players[i];
                    numbers[cnt] = bet.numbers[j];
                    amounts[cnt] = bet.amounts[j];
                    indexes[cnt] = j;

                    cnt++;
                }
            }
        }
    }

    function withdrawBets(uint256 tableId, uint256 roundId, uint256[] memory betIndexes)
        public
    {
        uint256 numBets = betIndexes.length;

        require(numBets > 0, INVALID_BET_INDEXES);

        (uint256 winnerNumber, uint256 mask) = getWinningNumber(tableId, roundId);

        require(mask != 0 && winnerNumber == 0, INVALID_ROUND);

        address msgSender = _msgSender();

        uint256 balance = token.balanceOf(address(this));

        Bet memory bet = _bets[tableId][roundId][msgSender];

        for (uint256 i = 0; i < numBets; i++) {
            uint256 betIndex = betIndexes[i];

            uint8 betType = uint8(bytes32(bet.numbers[betIndex])[0]);

            require(betType == COLOR_BET || betType == ODD_EVEN_BET || betType == LOW_HIGH_BET, INVALID_BET_TYPE);

            require(_enPrisonBets[tableId][roundId][msgSender][betIndex] == 0 && !_imprisonedBets[tableId][roundId][msgSender][betIndex], "Roulette: bet was withdrawn or imprisoned");

            _enPrisonBets[tableId][roundId][msgSender][betIndex] = BET_WITHDRAWED;

            uint256 amount = bet.amounts[betIndex] / 2;

            if (amount <= balance) {
                token.transfer(msgSender, amount);

                balance -= amount;

            } else {
                token.mint(msgSender, amount);
            }

            emit BetWithdrawed(tableId, roundId, msgSender, bet.numbers[betIndex], bet.amounts[betIndex], betIndex);
        }

        _refund(msgSender);
    }

    function imprisonBets(uint256 tableId, uint256 roundId, uint256[] memory betIndexes)
        public
    {
        uint256 numBets = betIndexes.length;

        require(numBets > 0, INVALID_BET_INDEXES);

        (uint256 winnerNumber, uint256 mask) = getWinningNumber(tableId, roundId);

        require(mask != 0 && winnerNumber == 0, INVALID_ROUND);

        require(!rounds[tableId][roundId + 1].closed, INVALID_NEXT_ROUND);

        address msgSender = _msgSender();

        Bet memory bet = _bets[tableId][roundId][msgSender];

        for (uint256 i = 0; i < numBets; i++) {
            uint256 betIndex = betIndexes[i];

            uint8 betType = uint8(bytes32(bet.numbers[betIndex])[0]);

            require(betType == COLOR_BET || betType == ODD_EVEN_BET || betType == LOW_HIGH_BET, INVALID_BET_TYPE);

            require(_enPrisonBets[tableId][roundId][msgSender][betIndex] == 0 && !_imprisonedBets[tableId][roundId][msgSender][betIndex], "Roulette: bet was withdrawn or imprisoned");

            _enPrisonBets[tableId][roundId][msgSender][betIndex] = BET_IMPRISONED;

            _imprisonBet(tableId, roundId + 1, msgSender, bet.numbers[betIndex], bet.amounts[betIndex]);
        }

        rounds[tableId][roundId + 1].numBets += numBets;

        _refund(msgSender);
    }

    function _imprisonBet(uint256 tableId, uint256 roundId, address account, uint256 number, uint256 amount)
        private 
    {
        Bet storage bet = _bets[tableId][roundId][account];

        uint256 betIndex = bet.numbers.length;

        if (betIndex == 0) {
            _participants[tableId][roundId].push(account);
        }

        _imprisonedBets[tableId][roundId][account][betIndex] = true;

        bet.numbers.push(number);
        bet.amounts.push(amount);

        emit BetImprisoned(tableId, roundId, account, number, amount, betIndex);
    }

     function setMinBetsAmount(uint256 tableId, uint256[] memory numbers, uint256[] memory values)
        public
        onlyOperator
    {
        for(uint256 i = 0; i < numbers.length; i++) {
            minBetsAmount[tableId][0][numbers[i]] = values[i];
        }

        emit MinBetsAmountUpdated(tableId, numbers, values);

        _refund(_msgSender());
    }

    function setMinTotalBetsAmount(uint256 tableId, uint256 value)
        public
        onlyOperator
    {
        require (tableId > 0 && tableId <= _tableCount, INVALID_TABLE_ID);

        _minTotalBetsAmount[tableId] = value;

        emit MinTotalBetsAmountUpdated(tableId, value);

        _refund(_msgSender());
    }

    function setDefaultMinTotalBets(uint256 value)
        public
        onlyOperator
    {
        _minTotalBetsAmount[0] = value;

        emit MinTotalBetsAmountUpdated(0, value);

        _refund(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IGameChainManager.sol";

contract DragonTiger is AccessControlEnumerableUpgradeable {
    
    uint256 public constant DRAGON_BET = 1;
    uint256 public constant TIGER_BET = 2;
    uint256 public constant TIE_BET = 3;
    uint256 public constant S_TIE_BET = 4;
    uint256 private constant MAX_BET_INDEX = 5;

    uint256 public constant DUE_RETURN = 0;

    uint256 public constant CARD_NUMBER = 52;
    uint256 public constant DECK_NUMBER = 8;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event BetRateUpdated(uint256 betType, uint256 rate);
    event NumMaxBetsUpdated(uint256 value);
    event RoundTimeUpdated(uint256 time);
    event TableCreated(uint256 tableId);
    event TableDisabled(uint256 tableId);
    event TableEnabled(uint256 tableId);

    event RoundStarted(uint256 tableId, uint256 roundId, bytes32 secretHash);
    event BetPlaced(uint256 tableId, uint256 roundId, bytes32 seedHash, address account, uint256 types, uint256 amount);
    event RoundEnded(uint256 tableId, uint256 roundId, uint256 secretValue);
    event RewardDistributed(uint256 tableId, uint256 roundId, address account, uint256 amount, uint256 reward, uint256 betType);
    event RefundDistributed(uint256 tableId, uint256 roundId, address account, uint256 amount, uint256 reward, uint256 betType);
    event BetWithdrawn(uint256 tableId, uint256 roundId, address account, uint256 amount, uint256 betType);

    event MaxTotalBetsUpdated(uint256 tableId, uint256 value);
    event MaxBetsUpdated(uint256 tableId, uint256[] types, uint256[] values );
    event MaxBetsReset(uint256 tableId);
    event MinBetsUpdated(uint256 tableId, uint256[] types, uint256[] values );
    event MinBetsReset(uint256 tableId);

    struct Round {
        bytes32 random;
        bytes32 secretHash;
        uint256 secretValue;
        uint256 numBets;
        bool closed;
        uint256 startAt;
        uint256 maxBet;
    }

    struct Bet {
        uint256[] types;
        uint256[] amounts;
        bytes32[] seedHashes;
        bool isWithdrawn;
    }

    IERC20 public token;

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

    // Now, it is unused but can't delete because smart contract is deployed by proxy
    uint256 public minBalance;

    uint256 public numMaxBets;

    uint256[] private _activeTables;

    uint256[] private _inactiveTables;

    mapping(uint256 => uint256) private _activeTableIndexs;
    mapping(uint256 => uint256) private _inactiveTableIndexs;

    uint256 private _tableCount;

    uint256 public roundTime;

    mapping(uint256 => mapping(uint256 => uint256)) public totalBetAmount;

    IGameChainManager public gameManager;

    // table id => round id => betType => max bet of round
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public maxBets;

    // table id => maxTotalBet
    mapping(uint256 => uint256) private _maxTotalBets;

    // table id => round id => betType => min bet of round
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public minBets;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Dragon Tiger: caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Dragon Tiger: caller is not operator");
        _;
    }

    function initialize(IERC20 _token, IGameChainManager _gameManager)
        external
        initializer
    {
        __AccessControlEnumerable_init();

        token = _token;
        gameManager = _gameManager;

        address msgSender = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, msgSender);
        _setupRole(OPERATOR_ROLE, msgSender);

        numMaxBets = 50;
        roundTime = 15 seconds;

        betRates[DRAGON_BET] = 100; // 1
        betRates[TIGER_BET] = 100;  // 1
        betRates[TIE_BET] = 1100;   // 11
        betRates[S_TIE_BET] = 5000; // 50
        betRates[DUE_RETURN] = 50;  // 0.5

        _activeTables.push(0);
        _inactiveTables.push(0);

        _configDefaultMinMaxBets();
    }

    function setGameManager(IGameChainManager _gameManager)
        external
        onlyAdmin
    {
        gameManager = _gameManager;
    }

    function setBetRate(uint256 betType, uint256 rate)
        external
        onlyAdmin
    {
        betRates[betType] = rate;

        emit BetRateUpdated(betType, rate);
    }

    function setNumMaxBets(uint256 value)
        external
        onlyAdmin
    {
        numMaxBets = value;

        emit NumMaxBetsUpdated(value);
    }

    function setRoundTime(uint256 time)
        external
        onlyAdmin
    {
        roundTime = time;

        emit RoundTimeUpdated(time);
    }

    function getCurrentRound(uint256 tableId)
        public
        view
        returns (uint256)
    {
        return _currentRound[tableId] + 1;
    }

    function getTotalParticipants(uint256 tableId, uint256 roundId)
        external
        view
        returns (uint256)
    {
        return _participants[tableId][roundId].length;
    }

    function getParticipants(uint256 tableId, uint256 roundId)
        external
        view
        returns (address[] memory)
    {
        return _participants[tableId][roundId];
    }

    function getBets(uint256 tableId, uint256 roundId, address account)
        external
        view
        returns (uint256[] memory, uint256[] memory, bytes32[] memory, bool currentStatus)
    {
        Bet memory bet = _bets[tableId][roundId][account];

        return (bet.types, bet.amounts, bet.seedHashes, !bet.isWithdrawn);
    }

    function getHash(uint256 value)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(value));
    }

    function createTable()
        external
        onlyOperator
    {
        uint256 id = ++_tableCount;

        _activeTableIndexs[id] = _activeTables.length;

        _activeTables.push(id);

        _maxTotalBets[id] = _maxTotalBets[0];

        for (uint256 i = 1; i < MAX_BET_INDEX; i++) {
            maxBets[id][0][i] = maxBets[0][0][i];
            minBets[id][0][i] = minBets[0][0][i];
        }

        emit TableCreated(id);

        gameManager.refillETH(_msgSender());
    }

    function enableTable(uint256 tableId)
        external
        onlyOperator
    {
        uint256 index = _inactiveTableIndexs[tableId];

        require(_activeTableIndexs[tableId] == 0 && index != 0, "Dragon Tiger: table id is invalid");

        _inactiveTableIndexs[tableId] = 0;

        _inactiveTables[index] = _inactiveTables[_inactiveTables.length - 1];
        _inactiveTables.pop();

        _activeTableIndexs[tableId] = _activeTables.length;

        _activeTables.push(tableId);

        emit TableEnabled(tableId);

        gameManager.refillETH(_msgSender());
    }

    function disableTable(uint256 tableId)
        external
        onlyOperator
    {
        uint256 index = _activeTableIndexs[tableId];

        require(_inactiveTableIndexs[tableId] == 0 && index != 0, "Dragon Tiger: table id is invalid");

        _activeTableIndexs[tableId] = 0;

        _activeTables[index] = _activeTables[_activeTables.length - 1];
        _activeTables.pop();

        _inactiveTableIndexs[tableId] = _inactiveTables.length;

        _inactiveTables.push(tableId);

        emit TableDisabled(tableId);

        gameManager.refillETH(_msgSender());
    }

    function getActiveTables()
        external
        view
        returns (uint256[] memory)
    {
        return _activeTables;
    }

    function getInactiveTables()
        external
        view
        returns (uint256[] memory)
    {
        return _inactiveTables;
    }

    function startRound(uint256 tableId, uint256 currentSecretValue, bytes32 nextSecretHash)
        external
        onlyOperator
    {
        uint256 roundId;

        if (currentSecretValue != 0) {
            roundId = getCurrentRound(tableId);

            Round storage round = rounds[tableId][roundId];

            require(block.timestamp >= round.startAt + roundTime, "Dragon Tiger: round is running");

            bytes32 secretHash = round.secretHash;

            require(secretHash != 0 && secretHash == getHash(currentSecretValue), "Dragon Tiger: secret value is invalid");

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

        require(nextSecretHash != 0, "Dragon Tiger: secret hash is invalid");

        roundId = getCurrentRound(tableId);

        require(rounds[tableId][roundId].secretHash == 0, "Dragon Tiger: round started");

        rounds[tableId][roundId] = Round(0, nextSecretHash, 0, 0, false, block.timestamp, _maxTotalBets[tableId]);

        for (uint256 i = 1; i < MAX_BET_INDEX; i++) {
            maxBets[tableId][roundId][i] = maxBets[tableId][0][i];
            minBets[tableId][roundId][i] = minBets[tableId][0][i];
        }

        emit RoundStarted(tableId, roundId, nextSecretHash);

        gameManager.refillETH(_msgSender());
    }

    function placeBet(uint256 tableId, bytes32 seedHash, uint256 btype, uint256 amount)
        external
    {
        require(seedHash != 0, "Dragon Tiger: seed hash is invalid");

        uint256 roundId = getCurrentRound(tableId);
        
        Round storage round = rounds[tableId][roundId];
        require(round.secretHash != 0, "Dragon Tiger: round has not started yet");
        require(round.numBets + 1 <= numMaxBets, "Dragon Tiger: number of bets reaches maximum");
        require(block.timestamp < round.startAt + roundTime, "Dragon Tiger: round closed");

        round.random ^= keccak256(abi.encodePacked(seedHash, btype, amount));

        address msgSender = _msgSender();

        Bet storage bet = _bets[tableId][roundId][msgSender];
        uint256 lastBet = bet.types.length;

        uint256 maxBetAllowed = maxBets[tableId][roundId][btype];

        require(lastBet == 0 || bet.isWithdrawn, "Dragon Tiger: player has placed bet for this round");
        require(amount > 0, "Dragon Tiger: bet amount is invalid");
        require(btype > 0 && betRates[btype] > 0, "Dragon Tiger: bet type is invalid");

        require(totalBetAmount[tableId][roundId] + amount <= round.maxBet, "Dragon Tiger: total exceeds maximum");
        require( maxBetAllowed == 0 || amount <= maxBetAllowed , "Dragon Tiger: bet exceeds maximum");
        require( minBets[tableId][roundId][btype] == 0 || amount >= minBets[tableId][roundId][btype] , "Dragon Tiger: bet should be greater than minimum amount");

        if (lastBet == 0) {
            _participants[tableId][roundId].push(msgSender);
        }

        bet.seedHashes.push(seedHash);
        bet.types.push(btype);
        bet.amounts.push(amount);
        bet.isWithdrawn = false;

        round.numBets += 1;

        totalBetAmount[tableId][roundId] += amount;
        
        token.transferFrom(msgSender, address(gameManager), amount);

        emit BetPlaced(tableId, roundId, seedHash, msgSender, btype, amount);

        gameManager.refillETH(_msgSender());
    }

    function withdrawBet(uint256 tableId)
        external
    {
        uint256 roundId = getCurrentRound(tableId);
        
        Round storage round = rounds[tableId][roundId];
        require(round.secretHash != 0, "Dragon Tiger: round has not started yet");
        require(block.timestamp < round.startAt + roundTime && !round.closed, "Dragon Tiger: round closed");

        address msgSender = _msgSender();

        Bet storage bet = _bets[tableId][roundId][msgSender];
        uint256 lastBet = bet.types.length;
        require(lastBet > 0 && !bet.isWithdrawn, "Dragon Tiger: player has not placed bet or withdrawn");

        uint256 amount = bet.amounts[lastBet - 1];

        gameManager.transferToken(msgSender, amount);
        round.numBets -= 1;
        bet.isWithdrawn = true;

        totalBetAmount[tableId][roundId] -= amount;

        emit BetWithdrawn(tableId, roundId, msgSender, amount, bet.types[lastBet - 1]);

        gameManager.refillETH(_msgSender());
    }

    function _distributeReward(uint256 tableId, uint256 roundId)
        private
    {
        (,uint256 result,uint256[] memory betsResult) = getResult(tableId, roundId);

        if (result != 0) {
            address[] memory players = _participants[tableId][roundId];

            uint256 numPlayers = players.length;

            uint256 totalReward = 0;

            for (uint256 i = 0; i < numPlayers; i++) {
                Bet memory bet = _bets[tableId][roundId][players[i]];

                if (bet.isWithdrawn) {
                    continue;
                }

                uint256 lastBet = bet.types.length - 1;
                uint256 lastBetType = bet.types[lastBet];
                uint256 lastBetAmount = bet.amounts[lastBet];

                bool isWin = (betsResult[lastBetType] == 1);
                bool isRefund = (betsResult[TIE_BET] == 1 && (lastBetType == TIGER_BET || lastBetType == DRAGON_BET));
                
                if (!isWin && !isRefund) {
                    continue;
                }
                uint256 reward;
                if (isWin) {
                    reward = (lastBetAmount * betRates[lastBetType]) / 100 + lastBetAmount;
                }

                if (isRefund) {
                    reward = (lastBetAmount * betRates[DUE_RETURN]) / 100;
                }

                gameManager.transferToken(players[i], reward);

                if (isRefund) {
                    emit RefundDistributed(tableId, roundId, players[i], lastBetAmount, reward, lastBetType);
                } else {
                    emit RewardDistributed(tableId, roundId, players[i], lastBetAmount, reward, lastBetType);
                }

                totalReward += reward;
            }

            uint256 totalBet = totalBetAmount[tableId][roundId];

            if (totalReward != totalBet) {
                gameManager.updateIncome(tableId, roundId, int256(totalBet) - int256(totalReward));
            }
        }
    }

    function getResult(uint256 tableId, uint256 roundId)
        public
        view
        returns (uint256[] memory cards, uint256 result, uint256[] memory betResults)
    {
        cards = new uint256[](2);
        uint256[2] memory vCards;
        // there is 4 types of betting currently supported
        betResults = new uint256[](MAX_BET_INDEX);

        Round memory round = rounds[tableId][roundId];

        if (!round.closed) {
            return (cards, result, betResults);
        }

        uint256 random = uint256(round.random);

        uint256 cnt = 0;

        // Generates 2 random cars
        while (cnt < 2) {
            uint256 card = random % (CARD_NUMBER * DECK_NUMBER) + 1;
            vCards[cnt] = card;
            random = uint256(keccak256(abi.encodePacked(random)));
            bool isDuplicated;
            for (uint256 i = 0; i < cnt; i++) {
                if (vCards[i] == vCards[cnt]) {
                    isDuplicated = true;
                    break;
                }
            }
            if (isDuplicated) {
                continue;
            }
            cards[cnt] = card % CARD_NUMBER;
            cnt++;
        }

        //calculate result
        uint256 dValue = cards[0] % 13;
        uint256 tValue = cards[1] % 13;

        if (dValue > tValue) {
            result = DRAGON_BET;
        } else if (dValue < tValue) {
            result = TIGER_BET;
        } else {
            result = TIE_BET;
        }
        betResults[result] = 1;
        if (cards[0] == cards[1]) {
            betResults[S_TIE_BET] = 1;
        }
        return (cards, result, betResults);
    }

    function getWinners(uint256 tableId, uint256 roundId)
        external
        view
        returns (address[] memory accounts, uint256[] memory amounts)
    {
        (uint256 cnt, address[] memory tmpAccounts, uint256[] memory tmpAmounts) = _getWinners(tableId, roundId);

        accounts = new address[](cnt);
        amounts = new uint256[](cnt);

        for (uint256 i = 0; i < cnt; i++) {
            accounts[i] = tmpAccounts[i];
            amounts[i] = tmpAmounts[i];
        }
    }

    function _getWinners(uint256 tableId, uint256 roundId)
        private
        view
        returns (uint256 cnt, address[] memory accounts, uint256[] memory amounts)
    {
        uint256 size = rounds[tableId][roundId].numBets;

        accounts = new address[](size);
        amounts = new uint256[](size);

        (,uint256 result,uint256[] memory betsResult) = getResult(tableId, roundId);

        if (result != 0) {
            address[] memory players = _participants[tableId][roundId];

            for (uint256 i = 0; i < players.length; i++) {
                Bet memory bet = _bets[tableId][roundId][players[i]];

                if (bet.isWithdrawn) {
                    continue;
                }

                uint256 lastBet = bet.types.length - 1;
                uint256 lastBetType = bet.types[lastBet];
                uint256 lastBetAmount = bet.amounts[lastBet];

                bool isWin = (betsResult[lastBetType] == 1);

                if (isWin) {
                    accounts[cnt] = players[i];
                    amounts[cnt] = lastBetAmount;
                }
                cnt++;
            }
        }
    }
    
    function setMaxTotal(uint256 tableId, uint256 value)
        public
        onlyOperator
    {
        require (tableId > 0 && tableId <= _tableCount, "DragonTiger: inavlid tableId");

        _maxTotalBets[tableId] = value;

        emit MaxTotalBetsUpdated(tableId, value);
    }

    function setDefaultMaxTotal(uint256 value)
        public
        onlyOperator
    {
        _maxTotalBets[0] = value;

        emit MaxTotalBetsUpdated(0, value);
    }
    
    function setMaxBets(uint256 tableId, uint256[] memory types, uint256[] memory values)
        public
        onlyOperator
    {
        for(uint256 i = 0; i < types.length; i++) {
            maxBets[tableId][0][types[i]] = values[i];
        }

        emit MaxBetsUpdated(tableId, types, values);
    }

    function resetDefaultMaxBets(uint256 tableId)
        public
        onlyOperator
    {
        for (uint256 i = 1; i < MAX_BET_INDEX; i++) {
            maxBets[tableId][0][i] = maxBets[0][0][i];
        }

        emit MaxBetsReset(tableId);
    }

    function setMinBets(uint256 tableId, uint256[] memory types, uint256[] memory values)
        public
        onlyOperator
    {
        for(uint256 i = 0; i < types.length; i++) {
            minBets[tableId][0][types[i]] = values[i];
        }

        emit MinBetsUpdated(tableId, types, values);
    }

    function resetDefaultMinBets(uint256 tableId)
        public
        onlyOperator
    {
        for (uint256 i = 1; i < MAX_BET_INDEX; i++) {
            minBets[tableId][0][i] = minBets[0][0][i];
        }

        emit MinBetsReset(tableId);
    }

    function getMaxTotalBets(uint256 tableId) 
        public
        view
        returns (uint256)
    {
        return _maxTotalBets[tableId];
    }
    
    function _configDefaultMinMaxBets() 
        private
    {
        _maxTotalBets[0] = 1000;
        maxBets[0][0][DRAGON_BET] = 100;
        maxBets[0][0][TIGER_BET] = 100; 
        maxBets[0][0][TIE_BET] = 100;   
        maxBets[0][0][S_TIE_BET] = 100; 
        maxBets[0][0][DUE_RETURN] = 100;

        minBets[0][0][DRAGON_BET] = 1;
        minBets[0][0][TIGER_BET] = 1; 
        minBets[0][0][TIE_BET] = 1;   
        minBets[0][0][S_TIE_BET] = 1; 
        minBets[0][0][DUE_RETURN] = 1;
    }
}

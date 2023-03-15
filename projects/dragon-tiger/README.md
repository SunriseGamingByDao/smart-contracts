# Dragon Tiger Smartcontract - Sunrise Gaming by DAO

## Contract Methods

### `initialize(IERC20 _token, IGameChainManager _gameManager)`

set SUSD {`_token`}, game manager {`_gameManager`} and init default params for contract

### `setGameManager(IGameChainManager _gameManager)`

add game manager {`_gameManager`}
Requirements:
- the caller must have the `DEFAULT_ADMIN_ROLE`.

### `setBetRate(uint256 betType, uint256 rate)`

set {`_rate`} for {`_betType`}
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{BetRateUpdated(betType, rate)}`

### `setNumMaxBets(uint256 value)`

Set maximum bet numbers for each round
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{NumMaxBetsUpdated(value)}`

### `setRoundTime(uint256 time)`

Set time for each round
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{RoundTimeUpdated(time)}`

### `getCurrentRound(uint256 tableId)`

Get current round of {`tableId`}

### `getTotalParticipants(uint256 tableId, uint256 roundId)`

Get total participants of {`roundId`} of {`tableId`}

### `getParticipants(uint256 tableId, uint256 roundId)`

Get participants of {`roundId`} of {`tableId`}

### `getBets(uint256 tableId, uint256 roundId, address account)`

Get bet data of player ${`account`} of {`roundId`} of {`tableId`}

### `getHash(uint256 value)`

Generate hash

### `createTable()`

Create new table
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{TableCreated(id)}`

### `enableTable(uint256 tableId)`

Enable table {`tableId`}
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{TableEnabled(tableId)}`

### `disableTable(uint256 tableId)`

Disable table {`tableId`}
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{TableDisabled(tableId)}`

### `getActiveTables()`

Get list of active tables

### `getInactiveTables()`

Get list of inactive tables

### `startRound(uint256 tableId, uint256 currentSecretValue, bytes32 nextSecretHash)`

- Calculate last round result base on {`currentSecretValue`}
- Distribute reward for winners of last round
- Start new round using {`nextSecretHash`}
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit:
- `{RoundEnded(tableId, roundId, currentSecretValue)}`
- `{RewardDistributed(tableId, roundId, account, betAmount, reward, betType)`
- `{RefundDistributed(tableId, roundId, account, betAmount, reward, betType)}`
- `{RoundStarted(tableId, roundId, nextSecretHash)}`

### `placeBet(uint256 tableId, bytes32 seedHash, uint256 btype, uint256 amount)`

Place bet to enjoy our game

Emit {`BetPlaced(tableId, roundId, seedHash, msgSender, betType, amount)`}

### `withdrawBet(uint256 tableId)`

Cancel last bet (of current round)

Emit {`BetWithdrawn(tableId, roundId, msgSender, amount, betType)`}

### `getResult(uint256 tableId, uint256 roundId)`

Get result of {`roundId`} of {`tableId`}

### `getWinners(uint256 tableId, uint256 roundId)`

Get winners of {`roundId`} of {`tableId`}

### `setMaxTotal(uint256 tableId, uint256 value)`

Set maximum total bet amount for each round of table {`tableId`}
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{MaxTotalBetsUpdated(tableId, value)}`

### `setDefaultMaxTotal(uint256 value)`

Set default maximum total bet amount for each round of table. New table will use this value after created.
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{MaxTotalBetsUpdated(0, value)}`

### `setMaxBets(uint256 tableId, uint256[] memory types, uint256[] memory values)`

Set maximum bet amount for each {`types`} of table {`tableId`}
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{MaxBetsUpdated(tableId, types, values)}`

### `resetDefaultMaxBets(uint256 tableId)`

Reset maximum bet amount for each {`types`} of table {`tableId`} to default value
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{MaxBetsReset(tableId)}`

### `setMinBets(uint256 tableId, uint256[] memory types, uint256[] memory values)`

Set minimum bet amount for each {`types`} of table {`tableId`}
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{MinBetsUpdated(tableId, types, values)}`

### `resetDefaultMinBets(uint256 tableId)`

Reset minimum bet amount for each {`types`} of table {`tableId`} to default value
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{MinBetsReset(tableId)}`

### `getMaxTotalBets(uint256 tableId)`

Get config for maximum total bets for each round of {`tableId`}

### `configDefaultMinMaxBet()`

Set default value for minimum maximum bet for each round of table. New table will use this value after created.
Requirements:
- the caller must have the `OPERATOR_ROLE`.

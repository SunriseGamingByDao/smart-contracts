# Sicbo Contract - Sunrise Gaming by DAO

## Contract Methods

### `initialize(IBetNumber _betNumber, IERC20 _token)`

set SUSD {`_token`}, game manager {`_gameManager`} and init default params for contract

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

### `setMinBalance(uint256 value)`

Set minimum gas balance to supply to player
Requirements:
- the caller must have the `OPERATOR_ROLE`.

Emit `{MinBalanceUpdated(value)}`

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

### `getBetStatus(uint256 tableId, uint256 roundId, address account, uint256 betIndex)`

Get bet status of player ${`account`} of {`roundId`} of {`tableId`}

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
- `{RewardDistributed(tableId, roundId, account, amount, betIndex)`
- `{RoundStarted(tableId, roundId, nextSecretHash)}`

### `placeBet(uint256 tableId, bytes32 seedHash, uint256[] memory types, uint256[] memory amounts)`

Place bet to enjoy our game

Emit {`BetPlaced(tableId, roundId, seedHash, msgSender, types, amounts)`}

### `getResult(uint256 tableId, uint256 roundId)`

Get result of {`roundId`} of {`tableId`}

### `getWinners(uint256 tableId, uint256 roundId)`

Get winners of {`roundId`} of {`tableId`}


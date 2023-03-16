**Important notice:** The publicly available source codes may not be used, altered, copied, or distributed without permission.

# Sunrise Gaming by DAO Contracts

This repo contains all the contracts used in Sunrise Gaming by DAO. It is divided in independent projects where each of them contains its smart contracts, test environment and unique config files.


## Existing projects

| Project name                                      | Description                                                                  | Solidity version(s)      |
| ------------------------------------------------- | ---------------------------------------------------------------------------- | ------------------------ |
| [Brige Contract](./projects/bridge)               | Implementation of Bridge Contracts to convert your USDC into SUSD.           | 0.8.7                    |
| [Roulette Contract](./projects/roulette)          | Implementation of Roulette Game.                                             | 0.8.9                    |
| [Baccarat Contract](./projects/baccarat)          | Implementation of Bacarrat Game.                                             | 0.8.7                    |
| [Sic bo Contract](./projects/sicbo)               | Implementation of Sic bo Game.                                               | 0.8.11                   |
| [Dragon Tiger Contract](./projects/dragon-tiger)  | Implementation of Dragon Tiger Game.                                         | 0.8.7                    |


## How we generate random number to determine game result

- When GAME OPERATOR start new round, he send SECRET_HASH of a `SECRET_VALUE`, the `SECRET_HASH` stored in contract for later used.

- Each time player place a new bet, player send their own `HASH_VALUE`, this value is combine with `SECRET_HASH`

```
    round.random ^= seedHash;
```
- When GAME OPERATOR end a round, he send the `SECRET_VALUE` to the contract, after that a random number is calculated base on following formular

```
    require(secretHash != 0 && secretHash == getHash(currentSecretValue), INVALID_SECRET_VALUE);

    round.random ^= getHash(uint256(secretHash) ^ currentSecretValue ^ block.timestamp);
```

- This random number is used to calculate game result

```
        number = uint256(round.random) % ROULETTE_NUMBER;
```

## How it works

### Play our games

Below sequence diagram illustrate how a game round happen
- Users enjoy our game by trigger contract to place their bet.
- Game contract log user bet on our Gaming CHAIN.
- Operator are in charge of trigger contract call to start new round every minute.
- Game contract calculate the result of previous round and distribute reward (or refund) to winner of last round.
- Game contract log previous round result & winners on our Gaming CHAIN.

```mermaid
sequenceDiagram
    participant User-1
    participant User-2
    participant Operator
    participant Game Contract
    participant SUSD Contract
loop Every minute
    Operator->>+Game Contract: start new round
    activate Game Contract

    opt "end previous round if exists"
    Game Contract ->>+ Game Contract: calculate random number & result
    Game Contract->>+SUSD Contract: distribute reward
    SUSD Contract-->>Game Contract: Success
    end
    
    Game Contract-->>Operator: Success
    deactivate Game Contract
    User-1->>+Game Contract: placeBet
    Game Contract-->>User-1: Success
    User-2->>+Game Contract: placeBet
    Game Contract-->>User-2: Success
end
```

### Gas Refund Mechanism

Our contract run on private Asset CHAIN & Game CHAIN.
The gas is auto supplied to user's wallet right after each contract call
to make sure that users never get gas related issues for their transaction on our Gaming Network.

### Link your ETH Wallet with your SUNC Wallet

For safety reason, a separate wallet on SUNC CHAINs (including Asset CHAIN & multiple Game CHAINs) should be linked to your main ETH wallet.

The registration process is as bellow.

```mermaid
sequenceDiagram
    participant User
    participant ETH Wallet
    participant SUNC Wallet
    participant PegBurn Contract

User ->>+ ETH Wallet: sign proof message
ETH Wallet -->> User: signature
User ->>+ SUNC Wallet: send signature
activate SUNC Wallet
SUNC Wallet ->>+ PegBurn Contract: register pair address with proof & signature
PegBurn Contract -->> SUNC Wallet: Success
SUNC Wallet -->> User: Success
deactivate SUNC Wallet
```

### Deposit USDC and get SUSD

User deposit USDC to our PegETH contract.
Regisetered validators should motinor the status of PegETH contract and votes to mint SUSD on our Asset CHAIN.

Below is simple illustration of the proccess.

```mermaid
sequenceDiagram
    participant ETH Wallet
    participant PegETH Contract
    participant Validators
    participant SUNC Wallet
    participant PegBurn Contract
    participant SUSD Contract

ETH Wallet ->>+ PegETH Contract: deposit
PegETH Contract -->> ETH Wallet: Success
loop Every minute
Validators ->>+ PegETH Contract: check for new deposit TXs
PegETH Contract -->> Validators: TXs data

activate PegBurn Contract
Validators ->>+ PegBurn Contract: vote to mint SUSD on Asset CHAIN
PegBurn Contract ->>+ SUSD Contract: mint SUSD to SUNC Wallet
SUSD Contract -->> PegBurn Contract: Success
PegBurn Contract->>Validators: Success
deactivate PegBurn Contract
end
```

### Withdraw SUSC and claim your USDC

User trigger withdraw call to our PegBurn contract.
Regisetered validators should motinor the status of PegBurn contract and issues their signatures to verify the request.
User should retrieves signatures from validators (via our [Lobby](https://lobby.sunrisegaming-dao.com/)),
then trigger the claim call to our PegETH contract.

Below is simple illustration of the proccess.

```mermaid
sequenceDiagram
    participant User
    participant ETH Wallet
    participant SUNC Wallet
    participant PegBurn Contract
    participant Validators
    participant PegETH Contract

User ->>+ SUNC Wallet: withdraw
activate ETH Wallet
SUNC Wallet ->>+ PegBurn Contract: withdraw USDC
PegBurn Contract -->> SUNC Wallet: Success
SUNC Wallet -->> User: Success
deactivate SUNC Wallet

loop Every minute
Validators ->>+ PegBurn Contract: check for new withdraw TXs
PegBurn Contract -->> Validators: TXs data
end

User ->>+ Validators: request signatures from validators
Validators -->> User: signatures

User ->>+ ETH Wallet: claim
activate ETH Wallet
ETH Wallet ->>+ PegETH Contract: claim (with validators signatures)
activate PegETH Contract
PegETH Contract ->>+ USDC Contract: transfer USDC to user wallet
USDC Contract -->> PegETH Contract: Success
PegETH Contract -->> ETH Wallet: Success
deactivate PegETH Contract
ETH Wallet -->> User: Success
deactivate ETH Wallet
```

### Transfer SUSD between Asset CHAIN and Game CHAIN

In orther to play game, user need to bridge SUDC between Asset CHAIN and Game CHAIN.

Below is simple illustration of the proccess.

```mermaid
sequenceDiagram
    participant SUNC Wallet
    participant Validators
    participant AssetChain Contract
    participant SUSD Contract (Asset CHAIN)
    participant GameChain Contract
    participant SUSD Contract (Game CHAIN)

    note right of SUNC Wallet: Asset CHAIN to Game CHAIN

SUNC Wallet ->>+ AssetChain Contract: deposit to Game CHAIN
activate AssetChain Contract
AssetChain Contract ->>+ SUSD Contract (Asset CHAIN): burn SUDS
SUSD Contract (Asset CHAIN) -->> AssetChain Contract: Success
AssetChain Contract -->> SUNC Wallet: Success
deactivate AssetChain Contract

loop Every minute
Validators ->>+ AssetChain Contract: check for new deposit TXs
AssetChain Contract -->> Validators: TXs data
end

Validators ->>+ GameChain Contract: vote to mint SUSD on Game CHAIN
activate GameChain Contract
GameChain Contract ->>+ SUSD Contract (Game CHAIN): mint SUSD to SUNC Wallet
SUSD Contract (Game CHAIN) -->> GameChain Contract: Success
GameChain Contract->>Validators: Success
deactivate GameChain Contract

    note right of SUNC Wallet: Game CHAIN to Asset CHAIN

SUNC Wallet ->>+ GameChain Contract: withdraw on Asset CHAIN
activate GameChain Contract
GameChain Contract -->>+ SUSD Contract (Game CHAIN): burn
SUSD Contract (Game CHAIN) -->> GameChain Contract: success
GameChain Contract -->> SUNC Wallet: Success
deactivate GameChain Contract

loop Every minute
Validators ->>+ GameChain Contract: check for new withdraw TXs
GameChain Contract -->> Validators: TXs data
end

Validators ->>+ AssetChain Contract: vote to mint SUSD on Game CHAIN
activate AssetChain Contract
AssetChain Contract ->>+ SUSD Contract (Asset CHAIN): mint SUSD to SUNC Wallet
SUSD Contract (Asset CHAIN) -->> AssetChain Contract: Success
AssetChain Contract->>Validators: Success
deactivate AssetChain Contract
```


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GameRouletteError {
    string constant NOT_ROLE_ADMIN = "GRE-1: caller is not admin";
    string constant NOT_ROLE_OPERATOR = "GRE-2: caller is not operator";
    string constant INVALID_TABLE_ID = "GRE-3: invalid tableId";
    string constant ROUND_IS_RUNNING = "GRE-4: round is running";
    string constant INVALID_SECRET_VALUE = "GRE-5: secret value is invalid";
    string constant INVALID_SECRET_HASH = "GRE-6: secret hash is invalid";
    string constant ROUND_WAS_STARTED = "GRE-7: round was started";
    string constant INVALID_SEED_HASH = "GRE-8: seed hash is invalid";
    string constant INVALID_LENGTH_ARRAY = "GRE-9: length of arrays is invalid";
    string constant ROUND_IS_NOT_START = "GRE-10: round is not started yet";
    string constant REACH_MAX_BETS = "GRE-11: number of bets reach maximum";
    string constant INVALID_AMOUNT = "GRE-12: amount is invalid";
    string constant INVALID_BET_NUMBER = "GRE-13: number format is invalid";
    string constant EXCEED_TOTAL_AMOUNT = "GRE-14: total exceeds maximum";
    string constant EXCEED_MAX_BET_AMOUNT = "GRE-15: bet exceeds maximum";
    string constant EXCEED_MIN_BET_AMOUNT = "GRE-16: bet should be greater than minimum amount";
    string constant EXCEED_TOTAL_MIN_BET = "GRE-16: total bet should be greater than total minimum amount";
    string constant INVALID_BET_INDEXES = "GRE-17: bet indexes is required";
    string constant INVALID_ROUND = "GRE-18: round id is invalid";
    string constant INVALID_BET_TYPE = "GRE-19: bet type is invalid";
    string constant INVALID_NEXT_ROUND = "GRE-20: next round is invalid";
}


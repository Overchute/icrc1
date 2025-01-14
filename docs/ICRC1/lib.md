# ICRC1/lib

## Type `Account`
``` motoko no-repl
type Account = T.Account
```


## Type `Subaccount`
``` motoko no-repl
type Subaccount = T.Subaccount
```


## Type `AccountBalances`
``` motoko no-repl
type AccountBalances = T.AccountBalances
```


## Type `Transaction`
``` motoko no-repl
type Transaction = T.Transaction
```


## Type `Balance`
``` motoko no-repl
type Balance = T.Balance
```


## Type `TransferArgs`
``` motoko no-repl
type TransferArgs = T.TransferArgs
```


## Type `Mint`
``` motoko no-repl
type Mint = T.Mint
```


## Type `BurnArgs`
``` motoko no-repl
type BurnArgs = T.BurnArgs
```


## Type `TransactionRequest`
``` motoko no-repl
type TransactionRequest = T.TransactionRequest
```


## Type `TransferError`
``` motoko no-repl
type TransferError = T.TransferError
```


## Type `SupportedStandard`
``` motoko no-repl
type SupportedStandard = T.SupportedStandard
```


## Type `InitArgs`
``` motoko no-repl
type InitArgs = T.InitArgs
```


## Type `TokenInitArgs`
``` motoko no-repl
type TokenInitArgs = T.TokenInitArgs
```


## Type `TokenData`
``` motoko no-repl
type TokenData = T.TokenData
```


## Type `MetaDatum`
``` motoko no-repl
type MetaDatum = T.MetaDatum
```


## Type `TxLog`
``` motoko no-repl
type TxLog = T.TxLog
```


## Type `TxIndex`
``` motoko no-repl
type TxIndex = T.TxIndex
```


## Type `TokenInterface`
``` motoko no-repl
type TokenInterface = T.TokenInterface
```


## Type `RosettaInterface`
``` motoko no-repl
type RosettaInterface = T.RosettaInterface
```


## Type `FullInterface`
``` motoko no-repl
type FullInterface = T.FullInterface
```


## Type `ArchiveInterface`
``` motoko no-repl
type ArchiveInterface = T.ArchiveInterface
```


## Type `GetTransactionsRequest`
``` motoko no-repl
type GetTransactionsRequest = T.GetTransactionsRequest
```


## Type `GetTransactionsResponse`
``` motoko no-repl
type GetTransactionsResponse = T.GetTransactionsResponse
```


## Type `QueryArchiveFn`
``` motoko no-repl
type QueryArchiveFn = T.QueryArchiveFn
```


## Type `TransactionRange`
``` motoko no-repl
type TransactionRange = T.TransactionRange
```


## Type `ArchivedTransaction`
``` motoko no-repl
type ArchivedTransaction = T.ArchivedTransaction
```


## Type `ArchiveTxWithoutCallback`
``` motoko no-repl
type ArchiveTxWithoutCallback = T.ArchiveTxWithoutCallback
```


## Type `TxResponseWithoutCallback`
``` motoko no-repl
type TxResponseWithoutCallback = T.TxResponseWithoutCallback
```


## Value `MAX_TRANSACTIONS_IN_LEDGER`
``` motoko no-repl
let MAX_TRANSACTIONS_IN_LEDGER
```


## Value `MAX_TRANSACTION_BYTES`
``` motoko no-repl
let MAX_TRANSACTION_BYTES : Nat64
```


## Value `MAX_TRANSACTIONS_PER_REQUEST`
``` motoko no-repl
let MAX_TRANSACTIONS_PER_REQUEST
```


## Function `init`
``` motoko no-repl
func init(args : InitArgs) : TokenData
```

Initialize a new ICRC-1 token

## Function `name`
``` motoko no-repl
func name(token : TokenData) : Text
```

Retrieve the name of the token

## Function `symbol`
``` motoko no-repl
func symbol(token : TokenData) : Text
```

Retrieve the symbol of the token

## Function `decimals`
``` motoko no-repl
func decimals() : Nat8
```

Retrieve the number of decimals specified for the token

## Function `fee`
``` motoko no-repl
func fee(token : TokenData) : Balance
```

Retrieve the fee for each transfer

## Function `set_fee`
``` motoko no-repl
func set_fee(token : TokenData, fee : Nat)
```

Set the fee for each transfer

## Function `metadata`
``` motoko no-repl
func metadata(token : TokenData) : [MetaDatum]
```

Retrieve all the metadata of the token

## Function `total_supply`
``` motoko no-repl
func total_supply(token : TokenData) : Balance
```

Returns the total supply of circulating tokens

## Function `minting_account`
``` motoko no-repl
func minting_account(token : TokenData) : Account
```

Returns the account with the permission to mint tokens

Note: **The minting account can only participate in minting
and burning transactions, so any tokens sent to it will be
considered burned.**

## Function `balance_of`
``` motoko no-repl
func balance_of(account : Account) : Balance
```

Retrieve the balance of a given account

## Function `supported_standards`
``` motoko no-repl
func supported_standards(token : TokenData) : [SupportedStandard]
```

Returns an array of standards supported by this token

## Function `transfer`
``` motoko no-repl
func transfer(token : TokenData, args : TransferArgs, caller : Principal) : async Result.Result<Balance, TransferError>
```

Transfers tokens from one account to another

## Function `mint`
``` motoko no-repl
func mint(token : TokenData, args : Mint, caller : Principal) : async Result.Result<Balance, TransferError>
```

Helper function to mint tokens with minimum args

## Function `burn`
``` motoko no-repl
func burn(token : TokenData, args : BurnArgs, caller : Principal) : async Result.Result<Balance, TransferError>
```

Helper function to burn tokens with minimum args

## Function `total_transactions`
``` motoko no-repl
func total_transactions(token : TokenData) : Nat
```

Returns the total number of transactions that have been processed by the given token.

## Function `get_transaction`
``` motoko no-repl
func get_transaction(token : TokenData, tx_index : ICRC1.TxIndex) : async ?Transaction
```

Retrieves the transaction specified by the given `tx_index`

## Function `get_transactions`
``` motoko no-repl
func get_transactions(token : TokenData, req : ICRC1.GetTransactionsRequest) : ICRC1.GetTransactionsResponse
```

Retrieves the transactions specified by the given range

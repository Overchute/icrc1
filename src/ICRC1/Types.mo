import Deque "mo:base/Deque";
import List "mo:base/List";
import Time "mo:base/Time";
import Result "mo:base/Result";

import STMap "mo:StableTrieMap";
import StableBuffer "mo:StableBuffer/StableBuffer";

module {

    public type Value = { #Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text };

    public type BlockIndex = Nat;
    public type Subaccount = Blob;
    public type Balance = Nat;
    public type StableBuffer<T> = StableBuffer.StableBuffer<T>;
    public type StableTrieMap<K, V> = STMap.StableTrieMap<K, V>;

    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };

    public type EncodedAccount = Blob;

    public type SupportedStandard = {
        name : Text;
        url : Text;
    };

    public type Memo = Blob;
    public type Timestamp = Nat64;
    public type Duration = Nat64;
    public type TxIndex = Nat;
    public type TxLog = StableBuffer<Transaction>;

    public type MetaDatum = (Text, Value);
    public type MetaData = [MetaDatum];

    public type OperationKind = {
        #mint;
        #burn;
        #transfer;
    };

    public type Mint = {
        to : Account;
        amount : Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type BurnArgs = {
        from_subaccount : ?Subaccount;
        amount : Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type Burn = {
        from : Account;
        amount : Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    /// Arguments for a transfer operation
    public type TransferArgs = {
        from_subaccount : ?Subaccount;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;

        /// The time at which the transaction was created.
        /// If this is set, the canister will check for duplicate transactions and reject them.
        created_at_time : ?Nat64;
    };

    public type Transfer = {
        from : Account;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type Operation = {
        #mint : Mint;
        #burn : Burn;
        #transfer : Transfer;
    };

    /// Internal representation of a transaction request
    public type TransactionRequest = {
        kind : OperationKind;
        from : Account;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
        encoded : {
            from : EncodedAccount;
            to : EncodedAccount;
        };
    };

    public type Transaction = {
        kind : Text;
        mint : ?Mint;
        burn : ?Burn;
        transfer : ?Transfer;
        timestamp : Timestamp;
    };

    public type TimeError = {
        #TooOld;
        #CreatedInFuture : { ledger_time : Timestamp };
    };

    public type TransferError = TimeError or {
        #BadFee : { expected_fee : Balance };
        #BadBurn : { min_burn_amount : Balance };
        #InsufficientFunds : { balance : Balance };
        #Duplicate : { duplicate_of : TxIndex };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };

    /// Interface for the ICRC token canister
    public type TokenInterface = actor {

        /// Returns the name of the token
        icrc1_name : shared query () -> async Text;

        /// Returns the symbol of the token
        icrc1_symbol : shared query () -> async Text;

        /// Returns the number of decimals the token uses
        icrc1_decimals : shared query () -> async Nat8;

        /// Returns the fee charged for each transfer
        icrc1_fee : shared query () -> async Balance;

        /// Returns the tokens metadata
        icrc1_metadata : shared query () -> async MetaData;

        /// Returns the total supply of the token
        icrc1_total_supply : shared query () -> async Balance;

        /// Returns the account that is allowed to mint new tokens
        icrc1_minting_account : shared query () -> async ?Account;

        /// Returns the balance of the given account
        icrc1_balance_of : shared query (Account) -> async Balance;

        /// Transfers the given amount of tokens from the sender to the recipient
        icrc1_transfer : shared (TransferArgs) -> async Result.Result<Balance, TransferError>;

        /// Returns the standards supported by this token's implementation
        icrc1_supported_standards : shared query () -> async [SupportedStandard];

    };

    public type TxCandidBlob = Blob;

    /// The Interface for the Archive canister
    public type ArchiveInterface = actor {
        /// Appends the given transactions to the archive.
        /// > Only the Ledger canister is allowed to call this method
        append_transactions : shared ([Transaction]) -> async Result.Result<(), Text>;

        /// Returns the total number of transactions stored in the archive
        total_transactions : shared query () -> async Nat;

        /// Returns the transaction at the given index
        get_transaction : shared query (TxIndex) -> async ?Transaction;

        /// Returns the transactions in the given range
        get_transactions : shared query (GetTransactionsRequest) -> async TransactionRange;

        /// Returns the number of bytes left in the archive before it is full
        /// > The capacity of the archive canister is 32GB
        remaining_capacity : shared query () -> async Nat;
    };

    public type InitArgs = {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        fee : Balance;
        minting_account : Account;
        max_supply : Balance;
        initial_balances : [(Account, Balance)];
        transaction_window : ?Timestamp;
        permitted_drift : ?Timestamp;
    };

    /// Init Args with optional fields for the token actor canister
    public type TokenInitArgs = {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        fee : Balance;
        max_supply : Balance;

        /// optional value that defaults to the caller if not provided
        minting_account : ?Account;

        initial_balances : [(Account, Balance)];
        /// defaults to 1 hour
        permitted_drift : ?Timestamp;
        /// defaults to 1 day
        transaction_window : ?Timestamp;
    };

    public type AccountBalances = StableTrieMap<EncodedAccount, Balance>;

    /// The details of the archive canister
    public type ArchiveData = {
        /// The reference to the archive canister
        var canister : ArchiveInterface;

        /// The number of transactions stored in the archive
        var stored_txs : Nat;
    };

    /// The state of the token canister
    public type TokenData = {
        /// The name of the token
        name : Text;

        /// The symbol of the token
        symbol : Text;

        /// The number of decimals the token uses
        decimals : Nat8;

        /// The fee charged for each transaction
        var fee : Balance;

        /// The maximum supply of the token
        max_supply : Balance;

        /// The account that is allowed to mint new tokens
        /// On initialization, the maximum supply is minted to this account
        minting_account : Account;

        /// The balances of all accounts
        accounts : AccountBalances;

        /// The metadata for the token
        metadata : StableBuffer<MetaDatum>;

        /// The standards supported by this token's implementation
        supported_standards : StableBuffer<SupportedStandard>;

        /// The time window in which duplicate transactions are not allowed
        transaction_window : Nat;

        permitted_drift : Nat;

        /// The recent transactions that have been processed by the ledger.
        /// Only the last 2000 transactions are stored before being archived.
        transactions : StableBuffer<Transaction>;

        /// The record that stores the details to the archive canister and number of transactions stored in it
        archive : ArchiveData;
    };

    // Rosetta API
    /// The type to request a range of transactions from the ledger canister
    public type GetTransactionsRequest = {
        start : TxIndex;
        length : Nat;
    };

    public type TransactionRange = {
        transactions: [Transaction];
    };

    public type QueryArchiveFn = shared query (GetTransactionsRequest) -> async TransactionRange;

    public type ArchivedTransaction = {
        /// The index of the first transaction to be queried in the archive canister
        start : TxIndex;
        /// The number of transactions to be queried in the archive canister
        length : Nat;

        /// The callback function to query the archive canister
        callback: QueryArchiveFn;
    };

    public type GetTransactionsResponse = {
        /// The number of valid transactions in the ledger and archived canisters that are in the given range
        log_length : Nat;

        /// the index of the first tx in the `transactions` field
        first_index : TxIndex;

        /// The transactions in the ledger canister that are in the given range
        transactions : [Transaction];

        /// Pagination request for archived transactions in the given range
        archived_transactions : [ArchivedTransaction];
    };

    public type ArchiveTxWithoutCallback = GetTransactionsRequest;

    /// This type is used in the library because shared types are only allowed as a public field of an actor
    public type TxResponseWithoutCallback = {
        log_length : Nat;

        first_index : TxIndex;

        transactions : [Transaction];

        archived_transactions : [ArchiveTxWithoutCallback];
    };

    /// Functions supported by the rosetta 
    public type RosettaInterface = actor {
        get_transactions : shared query (GetTransactionsRequest) -> async GetTransactionsResponse;
    };

    /// Interface of the ICRC token and Rosetta canister
    public type FullInterface = TokenInterface and RosettaInterface;

};

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Itertools "mo:itertools/Iter";
import StableBuffer "mo:StableBuffer/StableBuffer";
import STMap "mo:StableTrieMap";

import Account "Account";

import T "Types";
import U "Utils";

module {
    let { SB } = U;

    /// Checks if a transaction memo is valid
    public func validate_memo(memo : ?T.Memo) : Bool {
        switch (memo) {
            case (?bytes) {
                bytes.size() <= 32;
            };
            case (_) true;
        };
    };

    /// Checks if the `created_at_time` of a transfer request is before the accepted time range
    public func is_too_old(token : T.TokenData, created_at_time : Nat64) : Bool {
        let { permitted_drift; transaction_window } = token;

        let lower_bound = Time.now() - transaction_window - permitted_drift;
        Nat64.toNat(created_at_time) < lower_bound;
    };

    /// Checks if the `created_at_time` of a transfer request has not been reached yet relative to the canister's time.
    public func is_in_future(token : T.TokenData, created_at_time : Nat64) : Bool {
        let upper_bound = Time.now() + token.permitted_drift;
        Nat64.toNat(created_at_time) > upper_bound;
    };

    /// Checks if there is a duplicate transaction that matches the transfer request in the main canister.
    ///
    /// If a duplicate is found, the function returns an error (`#err`) with the duplicate transaction's index.
    public func deduplicate(token : T.TokenData, tx_req : T.TransactionRequest) : Result.Result<(), Nat> {
        // only deduplicates if created_at_time is set
        if (tx_req.created_at_time == null) {
            return #ok();
        };

        let { transactions = txs; archive } = token;

        var phantom_txs_size = 0;
        let phantom_txs = SB._clearedElemsToIter(txs);
        let current_txs = SB.vals(txs);

        let last_2000_txs = if (archive.stored_txs > 0) {
            phantom_txs_size := SB.capacity(txs) - SB.size(txs);
            Itertools.chain(phantom_txs, current_txs);
        } else {
            current_txs;
        };

        label for_loop for ((i, tx) in Itertools.enumerate(last_2000_txs)) {

            let is_duplicate = switch (tx_req.kind) {
                case (#mint) {
                    switch (tx.mint) {
                        case (?mint) {
                            ignore do ? {
                                if (is_too_old(token, mint.created_at_time!)) {
                                    break for_loop;
                                };
                            };

                            let mint_req : T.Mint = tx_req;

                            mint_req == mint;
                        };
                        case (_) false;
                    };
                };
                case (#burn) {
                    switch (tx.burn) {
                        case (?burn) {
                            ignore do ? {
                                if (is_too_old(token, burn.created_at_time!)) {
                                    break for_loop;
                                };
                            };
                            let burn_req : T.Burn = tx_req;

                            burn_req == burn;
                        };
                        case (_) false;
                    };
                };
                case (#transfer) {
                    switch (tx.transfer) {
                        case (?transfer) {
                            ignore do ? {
                                if (is_too_old(token, transfer.created_at_time!)) {
                                    break for_loop;
                                };
                            };

                            let transfer_req : T.Transfer = tx_req;

                            transfer_req == transfer;
                        };
                        case (_) false;
                    };
                };
            };

            if (is_duplicate) {
                let index = (archive.stored_txs + i - phantom_txs_size) : Nat;
                return #err(index);
            };
        };

        #ok();
    };

    /// Checks if a transfer request is valid
    public func validate_request(
        token : T.TokenData,
        tx_req : T.TransactionRequest,
    ) : Result.Result<(), T.TransferError> {

        if (tx_req.from == tx_req.to) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "The sender cannot have the same account as the recipient.";
                }),
            );
        };

        if (not Account.validate(tx_req.from)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Invalid account entered for sender.";
                }),
            );
        };

        if (not Account.validate(tx_req.to)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Invalid account entered for recipient";
                }),
            );
        };

        if (not validate_memo(tx_req.memo)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Memo must not be more than 32 bytes";
                }),
            );
        };

        let sender_balance : T.Balance = Account.get_balance(
            token.accounts,
            tx_req.encoded.from,
        );

        if (tx_req.amount > sender_balance) {
            return #err(#InsufficientFunds { balance = sender_balance });
        };

        switch (tx_req.created_at_time) {
            case (null) {};
            case (?created_at_time) {

                if (is_too_old(token, created_at_time)) {
                    return #err(#TooOld);
                };

                if (is_in_future(token, created_at_time)) {
                    return #err(
                        #CreatedInFuture {
                            ledger_time = Nat64.fromNat(Int.abs(Time.now()));
                        },
                    );
                };

                switch (deduplicate(token, tx_req)) {
                    case (#err(tx_index)) {
                        return #err(
                            #Duplicate {
                                duplicate_of = tx_index;
                            },
                        );
                    };
                    case (_) {};
                };
            };
        };

        #ok();
    };
};

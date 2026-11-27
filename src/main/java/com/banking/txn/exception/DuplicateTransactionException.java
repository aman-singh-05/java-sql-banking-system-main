package com.banking.txn.exception;

import com.banking.txn.model.TransactionStatus;

public class DuplicateTransactionException extends BankingException {
    public DuplicateTransactionException(String message) {
        super(message, TransactionStatus.REJECTED, "DUPLICATE_TRANSACTION");
    }
}
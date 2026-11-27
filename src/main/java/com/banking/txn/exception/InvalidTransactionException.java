package com.banking.txn.exception;

import com.banking.txn.model.TransactionStatus;

public class InvalidTransactionException extends BankingException {
    public InvalidTransactionException(String message) {
        super(message, TransactionStatus.REJECTED, "INVALID_TRANSACTION");
    }
}
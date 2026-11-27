package com.banking.txn.exception;

import com.banking.txn.model.TransactionStatus;

public class AccountNotFoundException extends BankingException {
    public AccountNotFoundException(String message) {
        super(message, TransactionStatus.REJECTED, "ACCOUNT_NOT_FOUND");
    }
}
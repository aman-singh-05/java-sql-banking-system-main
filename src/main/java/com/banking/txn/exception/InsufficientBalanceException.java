package com.banking.txn.exception;

import com.banking.txn.model.TransactionStatus;

public class InsufficientBalanceException extends BankingException {
    public InsufficientBalanceException(String message) {
        super(message, TransactionStatus.REJECTED, "INSUFFICIENT_BALANCE");
    }
}
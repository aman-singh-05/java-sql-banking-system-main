package com.banking.txn.exception;

import com.banking.txn.model.TransactionStatus;

public abstract class BankingException extends RuntimeException {
    private final TransactionStatus status;
    private final String errorCategory;

    protected BankingException(
            String message,
            TransactionStatus status,
            String errorCategory
    ) {
        super(message);
        this.status = status;
        this.errorCategory = errorCategory;
    }

    protected BankingException(
            String message,
            Throwable cause,
            TransactionStatus status,
            String errorCategory
    ) {
        super(message, cause);
        this.status = status;
        this.errorCategory = errorCategory;
    }

    public TransactionStatus getStatus() {
        return status;
    }

    public String getErrorCategory() {
        return errorCategory;
    }
}
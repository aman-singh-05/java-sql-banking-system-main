package com.banking.txn.model;

import java.math.BigDecimal;

public record TransactionRequest(
        String transactionId,
        String sourceAccount,
        String destinationAccount,
        BigDecimal amount,
        TransactionType type,
        String channel
) {
    public TransactionRequest {
        channel = (channel == null || channel.isBlank()) ? "API" : channel.trim();
    }
}
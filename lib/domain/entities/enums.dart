/// Types of financial accounts.
enum AccountType {
  /// A bank debit account — real money held in a bank.
  debit,

  /// Physical cash on hand.
  cash,

  /// A credit card — represents an IOU / liability.
  credit,

  /// A personal debt account — one per person.
  /// Positive balance = they owe me (receivable / piutang).
  /// Negative balance = I owe them (payable / hutang).
  debt,
}

/// Types of financial transactions.
enum TransactionType {
  /// Money going out (spending).
  expense,

  /// Money coming in (earning).
  income,

  /// Money moving between accounts.
  transfer,
}

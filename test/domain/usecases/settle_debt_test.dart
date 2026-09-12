import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/repositories/transaction_repository.dart';
import 'package:vent_expense_pro/domain/usecases/settle_debt.dart';

class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _accounts = {};

  void seed(List<Account> accounts) {
    for (final a in accounts) {
      _accounts[a.id] = a;
    }
  }

  Account? accountById(String id) => _accounts[id];

  @override
  Future<List<Account>> getAll() async => _accounts.values.toList();

  @override
  Future<Account?> getById(String id) async => _accounts[id];

  @override
  Future<Account> insert(Account account) async {
    _accounts[account.id] = account;
    return account;
  }

  @override
  Future<Account> update(Account account) async {
    _accounts[account.id] = account;
    return account;
  }

  @override
  Future<void> updateBalance(String id, int newBalance) async {
    final account = _accounts[id]!;
    _accounts[id] = account.copyWith(balance: newBalance);
  }

  @override
  Future<void> archive(String id) async {
    final account = _accounts[id]!;
    _accounts[id] = account.copyWith(isArchived: true);
  }

  @override
  Future<List<Account>> getByType(AccountType type) async =>
      _accounts.values.where((a) => a.type == type).toList();
}

class FakeTransactionRepository implements TransactionRepository {
  final Map<String, Transaction> _transactions = {};

  @override
  Future<List<Transaction>> getAll() async => _transactions.values.toList();

  @override
  Future<Transaction?> getById(String id) async => _transactions[id];

  @override
  Future<Transaction> insert(Transaction transaction) async {
    _transactions[transaction.id] = transaction;
    return transaction;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    _transactions[transaction.id] = transaction;
    return transaction;
  }

  @override
  Future<void> delete(String id) async {
    _transactions.remove(id);
  }

  @override
  Future<List<Transaction>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async =>
      _transactions.values
          .where((t) =>
              t.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
              t.dateTime.isBefore(end.add(const Duration(seconds: 1))))
          .toList();

  @override
  Future<List<Transaction>> getByAccount(String accountId) async =>
      _transactions.values
          .where((t) => t.accountId == accountId || t.toAccountId == accountId)
          .toList();
}

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late SettleDebt usecase;

  final now = DateTime.now();

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    usecase = SettleDebt(
      txnRepo,
      accountRepo,
    );
  });

  group('SettleDebt - Receiving Repayment (They owe us, balance > 0)', () {
    late Account friendDebt;
    late Account cashAccount;

    setUp(() {
      friendDebt = Account(
        id: 'debt_budi',
        name: 'Budi (Lent)',
        type: AccountType.debt,
        balance: 500000, // They owe us 500,000 (Receivable)
        currency: 'IDR',
        createdAt: now,
      );
      cashAccount = Account(
        id: 'acc_cash',
        name: 'Cash Pocket',
        type: AccountType.cash,
        balance: 100000,
        currency: 'IDR',
        createdAt: now,
      );
      accountRepo.seed([friendDebt, cashAccount]);
    });

    test('successfully settles full debt amount', () async {
      final txn = await usecase(
        debtAccountId: 'debt_budi',
        assetAccountId: 'acc_cash',
        amount: 500000,
      );

      expect(txn.amount, equals(500000));
      expect(txn.type, equals(TransactionType.transfer));
      expect(txn.isSettlement, isTrue);
      expect(txn.accountId, equals('debt_budi'));
      expect(txn.toAccountId, equals('acc_cash'));
      expect(txn.note, contains('Budi (Lent)'));

      // Debt balance should be reduced to 0
      final updatedDebt = accountRepo.accountById('debt_budi')!;
      expect(updatedDebt.balance, equals(0));

      // Cash balance should increase by 500,000
      final updatedCash = accountRepo.accountById('acc_cash')!;
      expect(updatedCash.balance, equals(600000));
    });

    test('successfully settles partial debt amount', () async {
      final txn = await usecase(
        debtAccountId: 'debt_budi',
        assetAccountId: 'acc_cash',
        amount: 200000,
      );

      expect(txn.amount, equals(200000));
      expect(txn.isSettlement, isTrue);

      final updatedDebt = accountRepo.accountById('debt_budi')!;
      expect(updatedDebt.balance, equals(300000));

      final updatedCash = accountRepo.accountById('acc_cash')!;
      expect(updatedCash.balance, equals(300000));
    });

    test('throws when amount exceeds receivable debt balance', () async {
      expect(
        () => usecase(
          debtAccountId: 'debt_budi',
          assetAccountId: 'acc_cash',
          amount: 600000,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('exceeds outstanding debt'),
        )),
      );
    });
  });

  group('SettleDebt - Paying Back Debt (We owe them, balance < 0)', () {
    late Account aniDebt;
    late Account bankAccount;

    setUp(() {
      aniDebt = Account(
        id: 'debt_ani',
        name: 'Ani (Borrowed)',
        type: AccountType.debt,
        balance: -300000, // We owe them 300,000 (Payable)
        currency: 'IDR',
        createdAt: now,
      );
      bankAccount = Account(
        id: 'acc_bank',
        name: 'Bank BCA',
        type: AccountType.debit,
        balance: 1000000,
        currency: 'IDR',
        createdAt: now,
      );
      accountRepo.seed([aniDebt, bankAccount]);
    });

    test('successfully repays full debt amount', () async {
      final txn = await usecase(
        debtAccountId: 'debt_ani',
        assetAccountId: 'acc_bank',
        amount: 300000,
      );

      expect(txn.amount, equals(300000));
      expect(txn.type, equals(TransactionType.transfer));
      expect(txn.isSettlement, isTrue);
      expect(txn.accountId, equals('acc_bank'));
      expect(txn.toAccountId, equals('debt_ani'));
      expect(txn.note, contains('Ani (Borrowed)'));

      // Debt balance moves from -300,000 towards 0 (+300,000)
      final updatedDebt = accountRepo.accountById('debt_ani')!;
      expect(updatedDebt.balance, equals(0));

      // Bank balance decreases by 300,000
      final updatedBank = accountRepo.accountById('acc_bank')!;
      expect(updatedBank.balance, equals(700000));
    });

    test('successfully repays partial debt amount', () async {
      final txn = await usecase(
        debtAccountId: 'debt_ani',
        assetAccountId: 'acc_bank',
        amount: 100000,
      );

      expect(txn.amount, equals(100000));

      // Debt balance moves from -300,000 to -200,000
      final updatedDebt = accountRepo.accountById('debt_ani')!;
      expect(updatedDebt.balance, equals(-200000));

      // Bank balance decreases by 100,000
      final updatedBank = accountRepo.accountById('acc_bank')!;
      expect(updatedBank.balance, equals(900000));
    });

    test('throws when asset account has insufficient balance to repay', () async {
      await accountRepo.updateBalance('acc_bank', 50000);

      expect(
        () => usecase(
          debtAccountId: 'debt_ani',
          assetAccountId: 'acc_bank',
          amount: 200000,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Insufficient balance'),
        )),
      );
    });

    test('throws when amount exceeds payable debt balance', () async {
      expect(
        () => usecase(
          debtAccountId: 'debt_ani',
          assetAccountId: 'acc_bank',
          amount: 400000,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('exceeds outstanding debt'),
        )),
      );
    });
  });

  group('SettleDebt - Validation & Edge Cases', () {
    test('throws when debt balance is zero', () async {
      final zeroDebt = Account(
        id: 'debt_zero',
        name: 'Settled Person',
        type: AccountType.debt,
        balance: 0,
        currency: 'IDR',
        createdAt: now,
      );
      final cash = Account(
        id: 'acc_cash',
        name: 'Cash',
        type: AccountType.cash,
        balance: 100000,
        currency: 'IDR',
        createdAt: now,
      );
      accountRepo.seed([zeroDebt, cash]);

      expect(
        () => usecase(
          debtAccountId: 'debt_zero',
          assetAccountId: 'acc_cash',
          amount: 50000,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('already fully settled'),
        )),
      );
    });

    test('throws when amount is negative or zero', () async {
      final debt = Account(
        id: 'debt_1',
        name: 'Person',
        type: AccountType.debt,
        balance: 100000,
        currency: 'IDR',
        createdAt: now,
      );
      final cash = Account(
        id: 'acc_cash',
        name: 'Cash',
        type: AccountType.cash,
        balance: 100000,
        currency: 'IDR',
        createdAt: now,
      );
      accountRepo.seed([debt, cash]);

      expect(
        () => usecase(
          debtAccountId: 'debt_1',
          assetAccountId: 'acc_cash',
          amount: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => usecase(
          debtAccountId: 'debt_1',
          assetAccountId: 'acc_cash',
          amount: -100,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when target debt account is not AccountType.debt', () async {
      final debit = Account(
        id: 'acc_debit',
        name: 'Debit',
        type: AccountType.debit,
        balance: 100000,
        currency: 'IDR',
        createdAt: now,
      );
      final cash = Account(
        id: 'acc_cash',
        name: 'Cash',
        type: AccountType.cash,
        balance: 100000,
        currency: 'IDR',
        createdAt: now,
      );
      accountRepo.seed([debit, cash]);

      expect(
        () => usecase(
          debtAccountId: 'acc_debit',
          assetAccountId: 'acc_cash',
          amount: 50000,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Not a debt account'),
        )),
      );
    });

    test('throws when asset account is not an asset', () async {
      final debt = Account(
        id: 'debt_1',
        name: 'Person',
        type: AccountType.debt,
        balance: 100000,
        currency: 'IDR',
        createdAt: now,
      );
      final credit = Account(
        id: 'acc_credit',
        name: 'Credit Card',
        type: AccountType.credit,
        balance: 100000,
        currency: 'IDR',
        createdAt: now,
      );
      accountRepo.seed([debt, credit]);

      expect(
        () => usecase(
          debtAccountId: 'debt_1',
          assetAccountId: 'acc_credit',
          amount: 50000,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Must settle using a debit or cash account'),
        )),
      );
    });
  });
}

import '../repositories/account_repository.dart';
import '../value_objects/money.dart';

/// Calculates the user's net financial position.
///
/// Net Position = Σ Asset balances − Σ Liability balances.
class CalculateNetPosition {
  final AccountRepository _accountRepository;

  CalculateNetPosition(this._accountRepository);

  /// Returns the net position as a [Money] value.
  ///
  /// Positive = user has more assets than debts.
  /// Negative = user owes more than they have.
  Future<Money> call() async {
    final accounts = await _accountRepository.getAll();

    int totalAssets = 0;
    int totalLiabilities = 0;

    for (final account in accounts) {
      if (account.isAsset) {
        totalAssets += account.balance;
      } else if (account.isLiability) {
        totalLiabilities += account.balance;
      }
    }

    return Money(cents: totalAssets - totalLiabilities);
  }

  /// Returns a breakdown: total assets, total liabilities, net position.
  Future<NetPositionBreakdown> breakdown() async {
    final accounts = await _accountRepository.getAll();

    int totalAssets = 0;
    int totalLiabilities = 0;

    for (final account in accounts) {
      if (account.isAsset) {
        totalAssets += account.balance;
      } else if (account.isLiability) {
        totalLiabilities += account.balance;
      }
    }

    return NetPositionBreakdown(
      totalAssets: Money(cents: totalAssets),
      totalLiabilities: Money(cents: totalLiabilities),
      netPosition: Money(cents: totalAssets - totalLiabilities),
    );
  }
}

/// A breakdown of the user's financial position.
class NetPositionBreakdown {
  final Money totalAssets;
  final Money totalLiabilities;
  final Money netPosition;

  const NetPositionBreakdown({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netPosition,
  });
}

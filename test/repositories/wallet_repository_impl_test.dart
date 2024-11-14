import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vent_expense_pro/models/wallet_model.dart';
import 'package:vent_expense_pro/repositories/impl/wallet_repository_impl.dart';

import 'wallet_repository_impl_test.mocks.dart';

@GenerateMocks([Database])
void main() {
  late WalletRepositoryImpl walletRepository;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockDatabase();
    walletRepository = WalletRepositoryImpl(mockDatabase);
  });

  group('WalletRepositoryImpl', () {
    test('getAllWallets returns list of wallets', () async {
      final mockResults = [
        {
          'wlt_id': 1,
          'wlt_name': 'Wallet1',
          'wlt_balance': 100.toDouble(),
          'created_at': '2024-01-01',
          'updated_at': '2024-01-02',
          'wlt_icon': 1,
          'icon_id': 1,
          'icon_code': 5598,
          'icon_color': '#FFFFFF',
        },
        {
          'wlt_id': 2,
          'wlt_name': 'Wallet2',
          'wlt_balance': 200.toDouble(),
          'created_at': '2024-02-01',
          'updated_at': '2024-02-02',
          'wlt_icon': 2,
          'icon_id': 2,
          'icon_code': 5598,
          'icon_color': '#000000',
        },
      ];

      when(mockDatabase.rawQuery(any)).thenAnswer((_) async => mockResults);

      final wallets = await walletRepository.getAllWallets();

      expect(wallets.length, 2);
      expect(wallets[0].id, 1);
      expect(wallets[1].id, 2);
      verify(mockDatabase.rawQuery(any)).called(1);
    });

    test('getWallet returns wallet by ID', () async {
      final walletId = 1;
      final mockResult = [
        {
          'wlt_id': walletId,
          'wlt_name': 'Wallet1',
          'wlt_balance': 100.toDouble(),
          'created_at': '2024-01-01',
          'updated_at': '2024-01-02',
          'wlt_icon': 1,
          'icon_id': 1,
          'icon_code': 5598,
          'icon_color': '#FFFFFF',
        }
      ];

      when(mockDatabase.query(
        any,
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      )).thenAnswer((_) async => mockResult);

      final wallet = await walletRepository.getWallet(walletId);

      expect(wallet, isNotNull);
      expect(wallet?.id, walletId);
      verify(mockDatabase.query(any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs'))).called(1);
    });

    test('getWallet returns null when no wallet is found', () async {
      when(mockDatabase.query(
        any,
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      )).thenAnswer((_) async => []);

      final wallet = await walletRepository.getWallet(999);

      expect(wallet, isNull);
      verify(mockDatabase.query(any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs'))).called(1);
    });

    test('createWallet inserts wallet and returns its ID', () async {
      final wallet = WalletModel(name: 'New Wallet', balance: 100);
      when(mockDatabase.insert(any, any)).thenAnswer((_) async => 1);

      final id = await walletRepository.createWallet(wallet);

      expect(id, 1);
      verify(mockDatabase.insert(any, wallet.toMap())).called(1);
    });

    test('updateWallet updates wallet and returns number of affected rows', () async {
      final wallet = WalletModel(id: 1, name: 'Updated Wallet', balance: 150);
      when(mockDatabase.update(
        any,
        any,
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      )).thenAnswer((_) async => 1);

      final rowsAffected = await walletRepository.updateWallet(wallet);

      expect(rowsAffected, 1);
      verify(mockDatabase.update(any, wallet.toMap(), where: anyNamed('where'), whereArgs: anyNamed('whereArgs'))).called(1);
    });

    test('deleteWallet deletes wallet by ID and returns number of affected rows', () async {
      final walletId = 1;
      when(mockDatabase.delete(
        any,
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      )).thenAnswer((_) async => 1);

      final rowsAffected = await walletRepository.deleteWallet(walletId);

      expect(rowsAffected, 1);
      verify(mockDatabase.delete(any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs'))).called(1);
    });
  });
}

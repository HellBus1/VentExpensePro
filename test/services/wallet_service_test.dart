import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vent_expense_pro/models/wallet_model.dart';
import 'package:vent_expense_pro/repositories/wallet_repository.dart';
import 'package:vent_expense_pro/services/wallet_service.dart';
import 'package:vent_expense_pro/commons/constants/constants.dart' as Constants;

import 'wallet_service_test.mocks.dart';

@GenerateMocks([WalletRepository])
void main() {
  late WalletService walletService;
  late MockWalletRepository mockRepository;

  setUp(() {
    mockRepository = MockWalletRepository();
    walletService = WalletService(mockRepository);
  });

  group('WalletService', () {
    test('getAllWallets returns a list of wallets', () async {
      final mockWallets = [
        WalletModel(id: 1, name: 'Wallet1', balance: 10),
        WalletModel(id: 2, name: 'Wallet2', balance: 10),
      ];

      when(mockRepository.getAllWallets()).thenAnswer((_) async => mockWallets);

      final result = await walletService.getAllWallets();

      expect(result, mockWallets);
      verify(mockRepository.getAllWallets()).called(1);
    });

    test('getAllWallets throws an exception when retrieval fails', () async {
      when(mockRepository.getAllWallets()).thenThrow(Exception());

      expect(() async => await walletService.getAllWallets(),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains(Constants.FAILED_TO_GET_LIST_OF_WALLET))));
    });

    test('getWallet returns a wallet by id', () async {
      final walletId = 1;
      final mockWallet = WalletModel(id: walletId, name: 'Wallet1', balance: 10);

      when(mockRepository.getWallet(walletId)).thenAnswer((_) async => mockWallet);

      final result = await walletService.getWallet(walletId);

      expect(result, mockWallet);
      verify(mockRepository.getWallet(walletId)).called(1);
    });

    test('getWallet throws an exception when retrieval fails', () async {
      final walletId = 1;
      when(mockRepository.getWallet(walletId)).thenThrow(Exception());

      expect(() async => await walletService.getWallet(walletId),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains(Constants.FAILED_TO_GET_WALLET))));
    });

    test('createWallet returns true when wallet is created successfully', () async {
      final newWallet = WalletModel(name: 'New Wallet', balance: 10);

      when(mockRepository.createWallet(newWallet)).thenAnswer((_) async => 1);

      final result = await walletService.createWallet(newWallet);

      expect(result, true);
      verify(mockRepository.createWallet(newWallet)).called(1);
    });

    test('createWallet throws an exception when creation fails', () async {
      final newWallet = WalletModel(name: 'New Wallet', balance: 10);

      when(mockRepository.createWallet(newWallet)).thenThrow(Exception());

      expect(() async => await walletService.createWallet(newWallet),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains(Constants.FAILED_TO_CREATE_WALLET))));
    });

    test('updateWallet returns true when wallet is updated successfully', () async {
      final existingWallet = WalletModel(id: 1, name: 'Updated Wallet', balance: 10);

      when(mockRepository.updateWallet(existingWallet)).thenAnswer((_) async => 1);

      final result = await walletService.updateWallet(existingWallet);

      expect(result, true);
      verify(mockRepository.updateWallet(existingWallet)).called(1);
    });

    test('updateWallet throws an exception when update fails', () async {
      final existingWallet = WalletModel(id: 1, name: 'Updated Wallet', balance: 10);

      when(mockRepository.updateWallet(existingWallet)).thenThrow(Exception());

      expect(() async => await walletService.updateWallet(existingWallet),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains(Constants.FAILED_TO_UPDATE_WALLET))));
    });

    test('deleteWallet returns true when wallet is deleted successfully', () async {
      final walletId = 1;

      when(mockRepository.deleteWallet(walletId)).thenAnswer((_) async => 1);

      final result = await walletService.deleteWallet(walletId);

      expect(result, true);
      verify(mockRepository.deleteWallet(walletId)).called(1);
    });

    test('deleteWallet throws an exception when deletion fails', () async {
      final walletId = 1;

      when(mockRepository.deleteWallet(walletId)).thenThrow(Exception());

      expect(() async => await walletService.deleteWallet(walletId),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains(Constants.FAILED_TO_DELETE_WALLET))));
    });
  });
}

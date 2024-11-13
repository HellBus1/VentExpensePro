import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:vent_expense_pro/commons/constants/constants.dart' as Constants;
import 'package:vent_expense_pro/dependency_injection.dart';
import 'package:vent_expense_pro/screens/wallet/provider/wallet_provider.dart';
import 'package:vent_expense_pro/screens/wallet/widgets/add_wallet_btn.dart';
import 'package:vent_expense_pro/screens/wallet/widgets/wallet_btn.dart';

class Wallet {
  final String name;
  final String balance;

  Wallet({required this.name, required this.balance});
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _WalletScreenState();
  }
}

class _WalletScreenState extends State<WalletScreen> {
  // final List<Wallet> wallets = [
  //   Wallet(name: 'Cash', balance: '989000'),
  //   Wallet(name: 'Bank Account', balance: '1500000'),
  //   Wallet(name: 'Savings', balance: '2000000'),
  // ];
  final additionalLastAddWalletButtonCount = 1;
  late final WalletProvider _walletProvider;

  @override
  void initState() {
    super.initState();
    _walletProvider = locator<WalletProvider>();
    _walletProvider.loadWallets();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    var localText = AppLocalizations.of(context);

    return ChangeNotifierProvider.value(
      value: _walletProvider,
      child: Consumer<WalletProvider>(builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final wallets = provider.wallets;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(localText?.wallets ?? Constants.EMPTY_STRING),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: height / 7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount:
                        wallets.length + additionalLastAddWalletButtonCount,
                    itemBuilder: (context, index) {
                      if (index == wallets.length) {
                        return AddWalletBtn();
                      }
                      return WalletBtn(
                        name: wallets[index].name,
                        balance: wallets[index].balance.toString(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

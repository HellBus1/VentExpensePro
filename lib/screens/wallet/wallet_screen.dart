import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:vent_expense_pro/commons/constants/constants.dart' as Constants;
import 'package:vent_expense_pro/dependency_injection.dart';
import 'package:vent_expense_pro/provider/wallet_provider.dart';
import 'package:vent_expense_pro/screens/wallet/widgets/add_wallet_btn.dart';
import 'package:vent_expense_pro/screens/wallet/widgets/wallet_btn.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _WalletScreenState();
  }
}

class _WalletScreenState extends State<WalletScreen> {
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
        if (provider.errorMessage != null &&
            provider.errorMessage!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage!),
              ),
            );

            provider.setErrorMessage(null);
          });
        }

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
                        wallet: wallets[index],
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

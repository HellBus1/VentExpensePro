import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:vent_expense_pro/dependency_injection.dart';
import 'package:vent_expense_pro/screens/bottom_nav.dart';
import 'package:vent_expense_pro/provider/wallet_provider.dart';

import 'commons/themes/theme.dart';
import 'commons/constants/constants.dart' as Constants;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupLocator();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => locator<WalletProvider>())
    ],
    child: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BottomNav(),
      title: Constants.APP_NAME,
      theme: buildLightTheme(Constants.CADMIUM_GREEN),
      darkTheme: buildDarkTheme(Constants.CADMIUM_GREEN),
    );
  }
}

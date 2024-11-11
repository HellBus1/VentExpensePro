import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vent_expense_pro/screens/bottom_nav.dart';

import 'commons/themes/theme.dart';
import 'commons/constants/constants.dart' as Constants;

void main() {
  runApp(const MainApp());
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

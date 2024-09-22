import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/providers/providers.dart';
import 'package:roomie_tasks/config/routes/routes.dart';
import 'package:roomie_tasks/config/theme/app_theme.dart';
import 'package:roomie_tasks/dependency_manager.dart';
import 'package:roomie_tasks/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ListenableProvider<GoogleSheetsSetupProvider>(
          create: (context) => sl.get<GoogleSheetsSetupProvider>(),
        ),
        ListenableProvider<RoommateProvider>(
          create: (context) => sl.get<RoommateProvider>(),
        ),
        ListenableProvider<TaskProvider>(
          create: (context) => sl.get<TaskProvider>(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

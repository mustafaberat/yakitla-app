library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/strings.dart';
import 'config/theme.dart';
import 'screens/shell.dart';
import 'services/catalog_cache.dart';
import 'services/fuel_controller.dart';
import 'services/settings_store.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsStore(prefs);
  final cache = CatalogCache(prefs);
  final fuel = FuelController(settings: settings, cache: cache);
  // Don't block first frame on network — cache paints immediately; fetch in bg.
  runApp(YakitlaApp(settings: settings, fuel: fuel));
  // ignore: unawaited_futures
  fuel.bootstrap();
}

class YakitlaApp extends StatelessWidget {
  const YakitlaApp({
    required this.settings,
    required this.fuel,
    super.key,
  });

  final SettingsStore settings;
  final FuelController fuel;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: fuel),
        ProxyProvider<SettingsStore, AppStrings>(
          update: (_, store, __) => store.s,
        ),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, store, _) {
          return MaterialApp(
            title: 'Yakıtla',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: store.themeMode,
            locale: store.lang == AppLang.en
                ? const Locale('en')
                : const Locale('tr'),
            supportedLocales: const [Locale('tr'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

/// Play Console screenshots for Yakıtla (tr / en / ar).
///
/// Run: `APP_ROOT=. ../lib/scripts/generate_game_images.sh`
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakitla/config/strings.dart';
import 'package:yakitla/config/theme.dart';
import 'package:yakitla/models/models.dart';
import 'package:yakitla/screens/calculate_tab.dart';
import 'package:yakitla/screens/prices_tab.dart';
import 'package:yakitla/screens/settings_tab.dart';
import 'package:yakitla/services/catalog_cache.dart';
import 'package:yakitla/services/fuel_controller.dart';
import 'package:yakitla/services/settings_store.dart';

const Size _phoneSize = Size(1080, 1920);
const String _outRoot = 'play/gorseller';

List<Station> _mockStations() {
  Station s({
    required String id,
    required String brand,
    required String name,
    required double gas,
    required double diesel,
  }) {
    return Station(
      id: id,
      name: name,
      brand: brand,
      address: 'Kadıköy, İstanbul',
      city: 'İSTANBUL',
      district: 'KADIKÖY',
      latitude: 40.99,
      longitude: 29.03,
      hasExactLocation: true,
      prices: FuelPrices(gasoline: gas, diesel: diesel),
      updatedAt: '2026-10-03T10:00:00.000Z',
      cityId: '34',
      districtId: '34-kadikoy',
    );
  }

  return [
    s(id: '1', brand: 'GO', name: 'GO Moda', gas: 48.42, diesel: 46.10),
    s(id: '2', brand: 'Kadoil', name: 'Kadoil Caferağa', gas: 48.90, diesel: 46.55),
    s(id: '3', brand: 'Opet', name: 'Opet Acıbadem', gas: 49.05, diesel: 46.80),
    s(id: '4', brand: 'Shell', name: 'Shell Caddebostan', gas: 48.70, diesel: 46.40),
  ];
}

ThemeData _shotTheme() {
  // Local Arial ("ShotSans") — GoogleFonts network is disabled in tests.
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'ShotSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: YakitlaColors.accent,
      brightness: Brightness.light,
      primary: YakitlaColors.accent,
      surface: YakitlaColors.card,
      onSurface: YakitlaColors.ink,
    ),
    scaffoldBackgroundColor: YakitlaColors.canvas,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'ShotSans'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'ShotSans'),
  );
}

Future<void> _loadShotFonts() async {
  Future<ByteData> fileBytes(String path) async {
    final data = await File(path).readAsBytes();
    return ByteData.sublistView(data);
  }

  // Arial Unicode covers TR/AR glyphs for Play screenshots.
  final sans = FontLoader('ShotSans');
  final unicode = File('/Library/Fonts/Arial Unicode.ttf');
  final arial = File('/System/Library/Fonts/Supplemental/Arial.ttf');
  sans.addFont(fileBytes(unicode.existsSync() ? unicode.path : arial.path));
  await sans.load();

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = FontLoader('MaterialIcons');
    icons.addFont(
      fileBytes(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
    await icons.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Play gorsellerini yaz', (tester) async {
    await tester.runAsync(_loadShotFonts);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (call) async => <String, dynamic>{
        'appName': 'Yakıtla',
        'packageName': 'com.arusoft.yakitla',
        'version': '1.0.0',
        'buildNumber': '1',
        'buildSignature': '',
        'installerStore': null,
      },
    );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final featureSrc = File('$_outRoot/ozellik-grafik/yakitla-1024x500.png');

    const langs = <(String, AppLang)>[
      ('tr', AppLang.tr),
      ('en', AppLang.en),
      ('ar', AppLang.ar),
    ];

    for (final entry in langs) {
      final folder = entry.$1;
      final lang = entry.$2;

      await prefs.clear();
      await prefs.setString('lang', folder);
      await prefs.setString('cityId', '34');
      await prefs.setString('districtId', '34-kadikoy');

      final settings = SettingsStore(prefs);
      await settings.setLang(lang);
      final fuel = FuelController(
        settings: settings,
        cache: CatalogCache(prefs),
      )
        ..cities = const [City(id: '34', name: 'İSTANBUL')]
        ..districts = const [
          District(id: '34-kadikoy', cityId: '34', name: 'KADIKÖY'),
        ]
        ..cityId = '34'
        ..districtId = '34-kadikoy'
        ..stations = _mockStations()
        ..state = LoadState.success
        ..updatedAt = '2026-10-03T10:00:00.000Z'
        ..locating = false;
      fuel.selected = fuel.stations.first;

      final bodies = <String, Widget>{
        '01-home': const PricesTab(),
        '02-duel': const CalculateTab(),
        '03-setup': const SettingsTab(),
        '04-howto': const PricesTab(),
        '05-over': const CalculateTab(),
      };

      for (final shot in bodies.entries) {
        _setView(tester, _phoneSize);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: settings),
                ChangeNotifierProvider.value(value: fuel),
                ProxyProvider<SettingsStore, AppStrings>(
                  update: (_, store, __) => store.s,
                ),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: _shotTheme(),
                locale: switch (lang) {
                  AppLang.en => const Locale('en'),
                  AppLang.ar => const Locale('ar'),
                  AppLang.tr => const Locale('tr'),
                },
                supportedLocales: const [
                  Locale('tr'),
                  Locale('en'),
                  Locale('ar'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: Scaffold(
                  body: shot.value,
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: shot.key.startsWith('02') ||
                            shot.key.startsWith('05')
                        ? 1
                        : shot.key.startsWith('03')
                            ? 2
                            : 0,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.local_gas_station_outlined),
                        selectedIcon:
                            const Icon(Icons.local_gas_station_rounded),
                        label: settings.s.tabPrices,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.calculate_outlined),
                        selectedIcon: const Icon(Icons.calculate_rounded),
                        label: settings.s.tabCalculate,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.settings_outlined),
                        selectedIcon: const Icon(Icons.settings_rounded),
                        label: settings.s.tabSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
        await _writePng(tester, key, '$_outRoot/$folder/${shot.key}.png');
      }

      if (featureSrc.existsSync()) {
        final dest = File('$_outRoot/$folder/feature.png');
        dest.parent.createSync(recursive: true);
        featureSrc.copySync(dest.path);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}

void _setView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding.zero;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

Future<void> _writePng(
  WidgetTester tester,
  GlobalKey key,
  String path,
) async {
  await tester.pump();
  final bytes = await tester.binding.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('wrote $path (${bytes.length} bytes)');
}

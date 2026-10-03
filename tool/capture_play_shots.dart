/// Play Console phone screenshots for Yakıtla (tr / en / ar).
///
/// Uses real BFF data (default `http://localhost:3000`, override with
/// `YAKITLA_API_BASE`) and a true phone logical viewport (390×844 @3x).
///
/// Run: `APP_ROOT=. ../lib/scripts/generate_game_images.sh`
library;

import 'dart:convert';
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

/// Phone logical size; rendered at 3× → 1170×2532 px (Play-friendly).
const Size _logicalPhone = Size(390, 844);
const double _dpr = 3;
/// Plain UI captures (vitrine compositor reads from here).
const String _outRoot = 'play/gorseller/raw';
const String _cityId = '34';
const String _districtId = '436'; // KADIKÖY

class _LiveCatalog {
  _LiveCatalog({
    required this.cities,
    required this.districts,
    required this.stations,
    required this.updatedAt,
  });

  final List<City> cities;
  final List<District> districts;
  final List<Station> stations;
  final String updatedAt;
}

/// Real BFF data via curl (flutter_test stubs HttpClient → always 400).
Future<_LiveCatalog> _loadLiveCatalog() async {
  final base = (Platform.environment['YAKITLA_API_BASE'] ??
          'http://localhost:3000')
      .replaceAll(RegExp(r'/$'), '');
  final fix = Directory('tool/fixtures');
  fix.createSync(recursive: true);

  Future<void> curl(String url, String out) async {
    final r = await Process.run('curl', ['-fsS', '-m', '90', url, '-o', out]);
    if (r.exitCode != 0) {
      throw StateError('curl failed $url: ${r.stderr}');
    }
  }

  await curl('$base/api/v1/fuel/cities', '${fix.path}/cities.json');
  await curl(
    '$base/api/v1/fuel/districts?cityId=$_cityId',
    '${fix.path}/districts.json',
  );
  await curl(
    '$base/api/v1/fuel/stations?cityId=$_cityId&districtId=$_districtId',
    '${fix.path}/stations.json',
  );

  Map<String, dynamic> read(String name) =>
      jsonDecode(File('${fix.path}/$name').readAsStringSync())
          as Map<String, dynamic>;

  final cities = (read('cities.json')['items'] as List? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(City.fromJson)
      .toList();
  final districts = (read('districts.json')['items'] as List? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(District.fromJson)
      .toList();
  final stationsRes = StationsResponse.fromJson(read('stations.json'));
  if (stationsRes.items.isEmpty) {
    throw StateError(
      'No stations from $base for city=$_cityId district=$_districtId',
    );
  }

  final stations = [...stationsRes.items]..sort((a, b) {
      final pa = a.prices.gasoline ?? double.infinity;
      final pb = b.prices.gasoline ?? double.infinity;
      return pa.compareTo(pb);
    });

  return _LiveCatalog(
    cities: cities,
    districts: districts,
    stations: stations,
    updatedAt: stationsRes.updatedAt,
  );
}

ThemeData _shotTheme() {
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
  final textTheme = base.textTheme.apply(
    fontFamily: 'ShotSans',
    fontFamilyFallback: const ['ShotArabic'],
    bodyColor: YakitlaColors.ink,
    displayColor: YakitlaColors.ink,
  );
  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: 'ShotSans',
      fontFamilyFallback: const ['ShotArabic'],
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: textTheme.labelLarge?.copyWith(
          fontFamily: 'ShotSans',
          fontFamilyFallback: const ['ShotArabic'],
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
  );
}

Future<void> _loadShotFonts() async {
  Future<ByteData> fileBytes(String path) async {
    final data = await File(path).readAsBytes();
    return ByteData.sublistView(data);
  }

  final dir = Directory('tool/fonts');
  final notoReg = File('${dir.path}/NotoSans-Regular.ttf');
  final notoBold = File('${dir.path}/NotoSans-Bold.ttf');
  final notoAr = File('${dir.path}/NotoSansArabic-Regular.ttf');

  final sans = FontLoader('ShotSans');
  if (notoReg.existsSync()) {
    sans.addFont(fileBytes(notoReg.path));
    if (notoBold.existsSync()) sans.addFont(fileBytes(notoBold.path));
  } else {
    sans.addFont(fileBytes('/Library/Fonts/Arial Unicode.ttf'));
  }
  await sans.load();

  if (notoAr.existsSync()) {
    final arabic = FontLoader('ShotArabic');
    arabic.addFont(fileBytes(notoAr.path));
    await arabic.load();
  }

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

    late _LiveCatalog catalog;
    await tester.runAsync(() async {
      catalog = await _loadLiveCatalog();
      // ignore: avoid_print
      print('live stations=${catalog.stations.length}');
    });

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
    final featureSrc =
        File('play/gorseller/ozellik-grafik/yakitla-1024x500.png');

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
      await prefs.setString('cityId', _cityId);
      await prefs.setString('districtId', _districtId);

      final settings = SettingsStore(prefs);
      await settings.setLang(lang);
      final fuel = FuelController(
        settings: settings,
        cache: CatalogCache(prefs),
      )
        ..cities = catalog.cities
        ..districts = catalog.districts
        ..cityId = _cityId
        ..districtId = _districtId
        ..stations = catalog.stations
        ..state = LoadState.success
        ..updatedAt = catalog.updatedAt
        ..locating = false;
      fuel.selected = fuel.stations.first;

      final bodies = <String, Widget>{
        '01-home': const PricesTab(),
        '02-duel': const CalculateTab(
          demoSelectFirstBrand: true,
          demoDistanceKm: 420,
          demoConsumptionLPer100: 7.2,
        ),
        '03-setup': const SettingsTab(),
      };

      for (final shot in bodies.entries) {
        _setPhoneView(tester);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MediaQuery(
              data: MediaQueryData(
                size: _logicalPhone,
                devicePixelRatio: _dpr,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
                textScaler: TextScaler.noScaling,
              ),
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
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        // Allow brand PNG/SVG decode + demo calculate seed.
        await tester.binding.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        // Keep scroll at top so station + Hesapla label stay in frame with results.
        if (shot.key == '02-duel') {
          final list = find.byType(Scrollable);
          if (list.evaluate().isNotEmpty) {
            await tester.drag(list.first, const Offset(0, 400));
            await tester.pumpAndSettle();
          }
        }
        await _writePng(tester, key, '$_outRoot/$folder/${shot.key}.png');
      }

      // Feature graphic lives next to locale folders, not under raw/.
      if (featureSrc.existsSync()) {
        final dest = File('play/gorseller/$folder/feature.png');
        dest.parent.createSync(recursive: true);
        featureSrc.copySync(dest.path);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}

void _setPhoneView(WidgetTester tester) {
  tester.view.physicalSize = Size(
    _logicalPhone.width * _dpr,
    _logicalPhone.height * _dpr,
  );
  tester.view.devicePixelRatio = _dpr;
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
    final image = await boundary.toImage(pixelRatio: _dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('wrote $path (${bytes.length} bytes)');
}

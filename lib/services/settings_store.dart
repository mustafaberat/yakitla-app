library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../config/strings.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kLang = 'lang';
  static const _kTheme = 'theme';
  static const _kCityId = 'cityId';
  static const _kDistrictId = 'districtId';
  static const _kFuelType = 'fuelType';
  static const _kPinnedStationId = 'pinnedStationId';

  AppLang get lang {
    final v = _prefs.getString(_kLang);
    if (v == 'en') return AppLang.en;
    return AppLang.tr;
  }

  ThemeMode get themeMode {
    switch (_prefs.getString(_kTheme)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get cityId => _prefs.getString(_kCityId) ?? ApiConfig.defaultCityId;
  String get districtId => _prefs.getString(_kDistrictId) ?? '';

  /// Persisted sort/highlight fuel: gasoline | diesel
  String get fuelType {
    final v = _prefs.getString(_kFuelType);
    if (v == 'diesel' || v == 'gasoline') return v!;
    return 'gasoline';
  }

  AppStrings get s => AppStrings(lang);

  Future<void> setLang(AppLang value) async {
    await _prefs.setString(_kLang, value == AppLang.en ? 'en' : 'tr');
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_kTheme, v);
    notifyListeners();
  }

  Future<void> setDefaultLocation({
    required String cityId,
    String districtId = '',
  }) async {
    await _prefs.setString(_kCityId, cityId);
    await _prefs.setString(_kDistrictId, districtId);
    notifyListeners();
  }

  Future<void> setFuelType(String type) async {
    if (type != 'gasoline' && type != 'diesel') return;
    await _prefs.setString(_kFuelType, type);
    notifyListeners();
  }

  String? get pinnedStationId {
    final v = _prefs.getString(_kPinnedStationId);
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<void> setPinnedStationId(String? id) async {
    if (id == null || id.isEmpty) {
      await _prefs.remove(_kPinnedStationId);
    } else {
      await _prefs.setString(_kPinnedStationId, id);
    }
    notifyListeners();
  }
}

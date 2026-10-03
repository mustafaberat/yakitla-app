library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Lightweight prefs cache for cities / districts (not a DB).
class CatalogCache {
  CatalogCache(this._prefs);

  final SharedPreferences _prefs;

  static const _citiesKey = 'cache:cities:v1';
  static const _citiesAtKey = 'cache:cities:v1:at';
  static const _districtPrefix = 'cache:districts:v1:';
  static const _districtAtPrefix = 'cache:districts:v1:at:';

  /// Catalog changes rarely — 7 days.
  static const ttl = Duration(days: 7);

  List<City>? readCities() {
    final raw = _prefs.getString(_citiesKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          if (e is Map) City.fromJson(Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return null;
    }
  }

  bool citiesFresh() {
    final at = _prefs.getInt(_citiesAtKey);
    if (at == null) return false;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at)) <
        ttl;
  }

  Future<void> writeCities(List<City> cities) async {
    final payload = jsonEncode([
      for (final c in cities) {'id': c.id, 'name': c.name},
    ]);
    await _prefs.setString(_citiesKey, payload);
    await _prefs.setInt(_citiesAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  List<District>? readDistricts(String cityId) {
    final raw = _prefs.getString('$_districtPrefix$cityId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          if (e is Map) District.fromJson(Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return null;
    }
  }

  bool districtsFresh(String cityId) {
    final at = _prefs.getInt('$_districtAtPrefix$cityId');
    if (at == null) return false;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at)) <
        ttl;
  }

  Future<void> writeDistricts(String cityId, List<District> districts) async {
    final payload = jsonEncode([
      for (final d in districts)
        {'id': d.id, 'cityId': d.cityId, 'name': d.name},
    ]);
    await _prefs.setString('$_districtPrefix$cityId', payload);
    await _prefs.setInt(
      '$_districtAtPrefix$cityId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}

library;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'catalog_cache.dart';
import 'settings_store.dart';

enum LoadState { idle, loading, success, empty, error }

class FuelController extends ChangeNotifier {
  FuelController({
    required this.settings,
    required this.cache,
    ApiClient? api,
  }) : api = api ?? ApiClient();

  final SettingsStore settings;
  final CatalogCache cache;
  final ApiClient api;

  List<City> cities = const [];
  List<District> districts = const [];
  List<Station> stations = const [];
  String updatedAt = '';
  String cityId = ApiConfig.defaultCityId;
  String districtId = '';
  String fuelType = FuelTypes.gasoline;
  Station? selected;
  LoadState state = LoadState.idle;
  String? error;
  String? catalogError;
  bool locating = false;
  bool catalogLoading = false;
  bool _bootstrapped = false;

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    cityId = settings.cityId;
    districtId = settings.districtId;
    fuelType = settings.fuelType;

    // Cache-first: paint UI immediately if we have prefs data.
    final cachedCities = cache.readCities();
    if (cachedCities != null && cachedCities.isNotEmpty) {
      cities = cachedCities;
      notifyListeners();
    }
    final cachedDistricts = cache.readDistricts(cityId);
    if (cachedDistricts != null && cachedDistricts.isNotEmpty) {
      districts = cachedDistricts;
      notifyListeners();
    }

    await ensureCities(force: !cache.citiesFresh());
    await ensureDistricts(cityId, force: !cache.districtsFresh(cityId));
    await loadStations();
  }

  /// Load cities from cache, then network only if missing/stale/forced.
  Future<void> ensureCities({bool force = false}) async {
    if (cities.isEmpty) {
      final cached = cache.readCities();
      if (cached != null && cached.isNotEmpty) {
        cities = cached;
        notifyListeners();
      }
    }

    final needNetwork = force || cities.isEmpty || !cache.citiesFresh();
    if (!needNetwork) return;

    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    try {
      final remote = await api.fetchCities();
      if (remote.isNotEmpty) {
        cities = remote;
        await cache.writeCities(remote);
        if (!cities.any((c) => c.id == cityId) && cities.isNotEmpty) {
          cityId = cities.first.id;
        }
      }
    } catch (e) {
      catalogError = e.toString();
      if (cities.isEmpty) error = catalogError;
    } finally {
      catalogLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureDistricts(String forCityId, {bool force = false}) async {
    if (forCityId.isEmpty) return;

    if (forCityId == cityId && districts.isEmpty) {
      final cached = cache.readDistricts(forCityId);
      if (cached != null && cached.isNotEmpty) {
        districts = cached;
        notifyListeners();
      }
    } else if (forCityId != cityId) {
      final cached = cache.readDistricts(forCityId);
      if (cached != null && cached.isNotEmpty && !force) {
        districts = cached;
        notifyListeners();
      }
    }

    final haveFresh = cache.districtsFresh(forCityId) &&
        cache.readDistricts(forCityId)?.isNotEmpty == true;
    if (!force && haveFresh && districts.isNotEmpty && forCityId == cityId) {
      return;
    }

    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    try {
      final remote = await api.fetchDistricts(forCityId);
      await cache.writeDistricts(forCityId, remote);
      if (forCityId == cityId) {
        districts = remote;
        if (districtId.isNotEmpty &&
            !districts.any((d) => d.id == districtId)) {
          districtId = '';
        }
      }
    } catch (e) {
      catalogError = e.toString();
      if (districts.isEmpty) error = catalogError;
    } finally {
      catalogLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStations() async {
    if (cityId.isEmpty) return;
    state = LoadState.loading;
    error = null;
    notifyListeners();
    try {
      final res = await api.fetchStations(
        cityId: cityId,
        districtId: districtId.isEmpty ? null : districtId,
      );
      updatedAt = res.updatedAt;
      if (res.items.isEmpty) {
        stations = const [];
        state = LoadState.empty;
        selected = null;
      } else {
        state = LoadState.success;
        final pinnedId = settings.pinnedStationId ?? selected?.id;
        Station? pinned;
        if (pinnedId != null) {
          for (final s in res.items) {
            if (s.id == pinnedId) {
              pinned = s;
              break;
            }
          }
        }
        selected = pinned;
        stations = _sort(res.items);
        // Keep a selected station for calculator even if nothing pinned.
        selected ??= stations.first;
      }
    } catch (e) {
      stations = const [];
      state = LoadState.error;
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> setCity(String id) async {
    if (id == cityId) {
      // Still ensure districts for this city (from cache or network).
      await ensureDistricts(id);
      return;
    }
    cityId = id;
    districtId = '';
    districts = cache.readDistricts(id) ?? const [];
    selected = null;
    await settings.setPinnedStationId(null);
    await settings.setDefaultLocation(cityId: cityId);
    notifyListeners();
    await ensureDistricts(id, force: !cache.districtsFresh(id));
    await loadStations();
  }

  Future<void> setDistrict(String id) async {
    if (id == districtId) return;
    districtId = id;
    selected = null;
    await settings.setPinnedStationId(null);
    await settings.setDefaultLocation(
      cityId: cityId,
      districtId: districtId,
    );
    await loadStations();
  }

  Future<void> setFuelType(String type) async {
    if (type == fuelType) return;
    fuelType = type;
    stations = _sort(stations);
    notifyListeners();
    await settings.setFuelType(type);
  }

  void selectStation(Station station) {
    selected = station;
    notifyListeners();
  }

  /// Pin station to top of the list (and persist).
  Future<void> pinStation(Station station) async {
    selected = station;
    await settings.setPinnedStationId(station.id);
    stations = _sort(stations);
    notifyListeners();
  }

  double? bestPriceFor(String type) {
    double? best;
    for (final s in stations) {
      final p = s.prices.forType(type);
      if (p == null || p <= 0) continue;
      if (best == null || p < best) best = p;
    }
    return best;
  }

  bool isBestPrice(Station station, String type) {
    final p = station.prices.forType(type);
    final best = bestPriceFor(type);
    if (p == null || best == null) return false;
    return (p - best).abs() < 0.001;
  }

  Future<void> useMyLocation() async {
    locating = true;
    error = null;
    notifyListeners();
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(settings.s.locationDenied);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final located = await api.locate(pos.latitude, pos.longitude);
      cityId = located.cityId;
      districtId = '';
      districts = cache.readDistricts(cityId) ?? const [];
      await settings.setDefaultLocation(cityId: cityId);
      notifyListeners();
      await ensureDistricts(cityId, force: !cache.districtsFresh(cityId));
      await loadStations();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  String get cityName {
    final match = cities.where((c) => c.id == cityId);
    if (match.isNotEmpty) return match.first.name;
    // Friendly fallback while catalog loads.
    if (cityId == '34') return 'İSTANBUL';
    return cityId;
  }

  String get districtName {
    if (districtId.isEmpty) return '';
    final match = districts.where((d) => d.id == districtId);
    return match.isEmpty ? '' : match.first.name;
  }

  List<Station> _sort(List<Station> items) {
    final pinnedId = settings.pinnedStationId ?? selected?.id;
    final copy = [...items];
    copy.sort((a, b) {
      if (pinnedId != null) {
        if (a.id == pinnedId && b.id != pinnedId) return -1;
        if (b.id == pinnedId && a.id != pinnedId) return 1;
      }
      final pa = a.prices.forType(fuelType);
      final pb = b.prices.forType(fuelType);
      if (pa == null && pb == null) {
        return a.brand.toLowerCase().compareTo(b.brand.toLowerCase());
      }
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pa.compareTo(pb);
    });
    return copy;
  }

  bool isPinned(Station station) => settings.pinnedStationId == station.id;
}

library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<List<City>> fetchCities() async {
    final data = await _getJson('/api/v1/fuel/cities');
    final items = data['items'] as List? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(City.fromJson)
        .toList();
  }

  Future<List<District>> fetchDistricts(String cityId) async {
    final data = await _getJson(
      '/api/v1/fuel/districts',
      query: {'cityId': cityId},
    );
    final items = data['items'] as List? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(District.fromJson)
        .toList();
  }

  Future<StationsResponse> fetchStations({
    required String cityId,
    String? districtId,
  }) async {
    final query = <String, String>{'cityId': cityId};
    if (districtId != null && districtId.isNotEmpty) {
      query['districtId'] = districtId;
    }
    final data = await _getJson('/api/v1/fuel/stations', query: query);
    return StationsResponse.fromJson(data);
  }

  Future<LocateResult> locate(double lat, double lon) async {
    final data = await _getJson(
      '/api/v1/fuel/locate',
      query: {'lat': '$lat', 'lon': '$lon'},
    );
    return LocateResult.fromJson(data);
  }

  /// Resolve Maps URL via BFF (prefers ServiceBox googleMapsUri).
  Future<String> resolveMapsUrl(Station station) async {
    final query = <String, String>{};
    final license = station.licenseNumber ??
        (station.id.contains('BAY/') ? station.id : null);
    if (license != null) query['license'] = license;
    if (station.brand.isNotEmpty) query['brand'] = station.brand;
    if (station.name.isNotEmpty) query['name'] = station.name;
    if (station.address.isNotEmpty) query['address'] = station.address;
    if (station.district.isNotEmpty) query['district'] = station.district;
    if (station.city.isNotEmpty) query['city'] = station.city;
    if (station.cityId != null) query['cityId'] = station.cityId!;
    if (station.hasExactLocation) {
      query['hasExactLocation'] = 'true';
      query['lat'] = '${station.latitude}';
      query['lon'] = '${station.longitude}';
    }
    try {
      final data = await _getJson('/api/v1/fuel/maps', query: query);
      final url = data['url']?.toString();
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {
      // fall through
    }
    // Local fallback (same as web stationMapsUrl search/coords).
    if (station.googleMapsUri != null) return station.googleMapsUri!;
    if (station.hasExactLocation) {
      return 'https://www.google.com/maps/dir/?api=1&destination='
          '${station.latitude},${station.longitude}';
    }
    final parts = <String>[
      if (station.address.trim().isNotEmpty) station.address.trim(),
      if (station.name.trim().isNotEmpty) station.name.trim(),
      if (station.brand.trim().isNotEmpty) station.brand.trim(),
      if (station.district.isNotEmpty && station.district != 'İlçe')
        station.district,
      if (station.city.isNotEmpty) station.city,
      'akaryakıt',
    ];
    return 'https://www.google.com/maps/search/?api=1&query='
        '${Uri.encodeComponent(parts.join(' '))}';
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    late http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 25));
    } catch (_) {
      throw ApiException('Bağlantı hatası. İnterneti kontrol edin.');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Geçersiz yanıt (${res.statusCode}).');
    }

    if (res.statusCode >= 400) {
      final err = body['error'] as Map<String, dynamic>?;
      throw ApiException(
        err?['message']?.toString() ?? 'İstek başarısız (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    return body;
  }
}

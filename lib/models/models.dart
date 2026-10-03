library;

typedef FuelType = String;

abstract final class FuelTypes {
  static const gasoline = 'gasoline';
  static const diesel = 'diesel';
  static const all = [gasoline, diesel];
}

class City {
  const City({required this.id, required this.name});

  final String id;
  final String name;

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: '${json['id']}',
        name: '${json['name']}',
      );
}

class District {
  const District({
    required this.id,
    required this.cityId,
    required this.name,
  });

  final String id;
  final String cityId;
  final String name;

  factory District.fromJson(Map<String, dynamic> json) => District(
        id: '${json['id']}',
        cityId: '${json['cityId']}',
        name: '${json['name']}',
      );
}

class FuelPrices {
  const FuelPrices({this.gasoline, this.diesel});

  final double? gasoline;
  final double? diesel;

  double? forType(String type) {
    switch (type) {
      case FuelTypes.gasoline:
        return gasoline;
      case FuelTypes.diesel:
        return diesel;
      default:
        return null;
    }
  }

  factory FuelPrices.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FuelPrices();
    return FuelPrices(
      gasoline: _num(json['gasoline']),
      diesel: _num(json['diesel']),
    );
  }
}

class Station {
  const Station({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.hasExactLocation,
    required this.prices,
    required this.updatedAt,
    this.cityId,
    this.districtId,
    this.distanceKm,
    this.licenseNumber,
    this.googleMapsUri,
  });

  final String id;
  final String name;
  final String brand;
  final String address;
  final String city;
  final String district;
  final String? cityId;
  final String? districtId;
  final double latitude;
  final double longitude;
  final bool hasExactLocation;
  final FuelPrices prices;
  final String updatedAt;
  final double? distanceKm;
  final String? licenseNumber;
  final String? googleMapsUri;

  factory Station.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? const {};
    final distance = json['distance'] as Map<String, dynamic>?;
    final license = json['licenseNumber']?.toString();
    final mapsUri = json['googleMapsUri']?.toString();
    return Station(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      brand: '${json['brand'] ?? ''}',
      address: '${json['address'] ?? ''}',
      city: '${json['city'] ?? ''}',
      district: '${json['district'] ?? ''}',
      cityId: json['cityId']?.toString(),
      districtId: json['districtId']?.toString(),
      latitude: _num(loc['latitude']) ?? 0,
      longitude: _num(loc['longitude']) ?? 0,
      hasExactLocation: json['hasExactLocation'] == true,
      prices: FuelPrices.fromJson(json['prices'] as Map<String, dynamic>?),
      updatedAt: '${json['updatedAt'] ?? ''}',
      distanceKm: _num(distance?['value']),
      licenseNumber: (license != null && license.isNotEmpty) ? license : null,
      googleMapsUri:
          (mapsUri != null && mapsUri.isNotEmpty) ? mapsUri : null,
    );
  }
}

class StationsResponse {
  const StationsResponse({required this.items, required this.updatedAt});

  final List<Station> items;
  final String updatedAt;

  factory StationsResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Station.fromJson)
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return StationsResponse(
      items: items,
      updatedAt: '${meta['updatedAt'] ?? ''}',
    );
  }
}

class LocateResult {
  const LocateResult({required this.cityId, required this.cityName});

  final String cityId;
  final String cityName;

  factory LocateResult.fromJson(Map<String, dynamic> json) => LocateResult(
        cityId: '${json['cityId']}',
        cityName: '${json['cityName']}',
      );
}

class CalculateResult {
  const CalculateResult({
    required this.fuelConsumedLitres,
    required this.totalCost,
    required this.costPerKm,
  });

  final double fuelConsumedLitres;
  final double totalCost;
  final double costPerKm;
}

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

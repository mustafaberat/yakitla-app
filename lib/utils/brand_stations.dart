library;

import '../models/models.dart';

double? _avg(Iterable<double?> values) {
  final nums = values.whereType<double>().toList();
  if (nums.isEmpty) return null;
  return nums.reduce((a, b) => a + b) / nums.length;
}

/// One card per brand with averaged prices (avoids "cheapest" claims).
List<Station> brandAverageStations(List<Station> stations) {
  final byBrand = <String, List<Station>>{};
  for (final s in stations) {
    final key = s.brand.trim();
    if (key.isEmpty) continue;
    byBrand.putIfAbsent(key, () => []).add(s);
  }

  final brands = byBrand.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return brands.map((brand) {
    final group = byBrand[brand]!;
    group.sort((a, b) {
      final la = (a.licenseNumber?.isNotEmpty ?? false) ? 0 : 1;
      final lb = (b.licenseNumber?.isNotEmpty ?? false) ? 0 : 1;
      if (la != lb) return la - lb;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    final rep = group.first;
    final count = group.length;
    return Station(
      id: 'brand:$brand',
      name: count > 1 ? '$count istasyon · ortalama' : rep.name,
      brand: brand,
      address: rep.address,
      city: rep.city,
      district: rep.district,
      cityId: rep.cityId,
      districtId: rep.districtId,
      latitude: rep.latitude,
      longitude: rep.longitude,
      hasExactLocation: rep.hasExactLocation,
      prices: FuelPrices(
        gasoline: _avg(group.map((s) => s.prices.gasoline)),
        diesel: _avg(group.map((s) => s.prices.diesel)),
      ),
      updatedAt: rep.updatedAt,
      licenseNumber: rep.licenseNumber,
      googleMapsUri: rep.googleMapsUri,
    );
  }).toList();
}

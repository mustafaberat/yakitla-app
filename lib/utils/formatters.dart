library;

import 'package:intl/intl.dart';

import '../models/models.dart';

String formatPrice(double? value, {String dash = '—'}) {
  if (value == null || value <= 0) return dash;
  // Explicit ₺ + tr digits — avoids tofu when a font lacks the currency glyph
  // from NumberFormat.currency's composed symbol.
  final n = NumberFormat('#,##0.00', 'tr_TR');
  return '₺${n.format(value)}';
}

String formatMoney(double value) {
  final n = NumberFormat('#,##0.00', 'tr_TR');
  return '₺${n.format(value)}';
}

String formatUpdatedAt(String iso, {String todayLabel = 'Bugün', String dash = '—'}) {
  if (iso.isEmpty) return dash;
  try {
    final dt = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time = DateFormat('HH:mm').format(dt);
    if (sameDay) return '$todayLabel $time';
    return DateFormat('d MMM HH:mm', 'tr_TR').format(dt);
  } catch (_) {
    return iso;
  }
}

String stationSubtitle(Station station) {
  final name = station.name.trim();
  final brand = station.brand.trim();
  if (name.isNotEmpty && name.toLowerCase() != brand.toLowerCase()) {
    return name;
  }
  final address = station.address.trim();
  if (address.isNotEmpty && address != ',' && address.length > 2) {
    return address;
  }
  if (station.district.isNotEmpty && station.district != 'İlçe') {
    return '${station.district}, ${station.city}';
  }
  return station.city;
}

String stationMapsUrl(Station station) {
  if (station.hasExactLocation &&
      (station.latitude != 0 || station.longitude != 0)) {
    return 'https://www.google.com/maps/dir/?api=1&destination='
        '${station.latitude},${station.longitude}';
  }
  final parts = <String>[
    if (station.address.trim().isNotEmpty && station.address.trim() != ',')
      station.address.trim()
    else ...[
      if (station.name.trim().isNotEmpty) station.name.trim(),
      if (station.brand.trim().isNotEmpty) station.brand.trim(),
    ],
    if (station.district.isNotEmpty && station.district != 'İlçe')
      station.district,
    if (station.city.isNotEmpty) station.city,
    'akaryakıt',
  ];
  final q = Uri.encodeComponent(parts.join(' '));
  return 'https://www.google.com/maps/search/?api=1&query=$q';
}

CalculateResult calculateTrip({
  required double distanceKm,
  required double consumptionLPer100Km,
  required double pricePerLitre,
}) {
  final fuel = (distanceKm * consumptionLPer100Km) / 100;
  final total = fuel * pricePerLitre;
  return CalculateResult(
    fuelConsumedLitres: _round2(fuel),
    totalCost: _round2(total),
    costPerKm: _round2(total / distanceKm),
  );
}

double _round2(double n) => (n * 100).round() / 100;

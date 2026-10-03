import 'package:flutter_test/flutter_test.dart';
import 'package:yakitla/utils/formatters.dart';

void main() {
  test('calculateTrip matches web formula', () {
    final r = calculateTrip(
      distanceKm: 100,
      consumptionLPer100Km: 7.5,
      pricePerLitre: 48,
    );
    expect(r.fuelConsumedLitres, 7.5);
    expect(r.totalCost, 360);
    expect(r.costPerKm, 3.6);
  });
}
